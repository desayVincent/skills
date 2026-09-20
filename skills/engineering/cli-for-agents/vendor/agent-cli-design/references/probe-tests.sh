#!/bin/sh
# probe-tests.sh — self-test for probe.sh. Run: sh references/probe-tests.sh
#
# probe.sh is prescribed as a mechanical release gate, so its own failure modes
# matter as much as the target's: a harness that can false-pass, hang, or blame
# its own misconfiguration on the CLI is worse than no harness. These cases pin
# the guarantees the header claims.
#
# Every probe.sh invocation runs under an INDEPENDENT outer watchdog, so a
# regression that restores the unbounded hang fails the test instead of
# hanging the suite.
#
# EXPECTED RUNTIME ~70s — it is not hung. Roughly 12s of that is one case that
# must genuinely wait out a TERM-ignoring target's deadline and kill grace; the
# rest is ~30 --all runs, each spawning a few hundred short-lived processes.
# Progress prints per case, so a stalled line tells you which case is stuck.
set -u
P=$(dirname "$0")/probe.sh
D=$(mktemp -d); trap 'rm -rf "$D"' EXIT
PASS=0; FAIL=0

# A target that ignores TERM and spins: only a real KILL escalation stops it.
cat >"$D/stubborn" <<'EOF'
#!/bin/sh
trap '' TERM
while :; do :; done
EOF
chmod +x "$D/stubborn"

LOG=$D/argv.log

# The target under test. Two properties matter, and both are deliberate:
#
#  1. The schema is baked into the script TEXT, not read from the environment.
#     probe.sh runs the target under `env -i`, so an exported schema would never
#     arrive and every --all case would silently test an empty schema instead.
#  2. It is PATH-SENSITIVE and RECORDS EVERY INVOCATION. A fixture that merely
#     accepts any argv containing --help cannot distinguish "probed db migrate"
#     from "printed the heading and probed root", so asserting on probe.sh's own
#     headings proves nothing about coverage. Assertions here read $LOG, which
#     only the target writes.
#
# <fail-path> is the one command path whose help is broken ('' = root,
# NONE = nothing is broken).
mkstub() { # mkstub <schema-json> <fail-path>
  { echo '#!/bin/sh'
    echo "LOG='$LOG'"
    echo "FAILPATH='$2'"
    cat <<'STUB'
p=""; want=0
for a in "$@"; do
  case $a in
    --help) want=1 ;;
    -*)     ;;
    *)      p="${p:+$p }$a" ;;
  esac
done
if [ "$want" -eq 1 ]; then
  printf 'help:[%s]\n' "$p" >>"$LOG"
  if [ "$p" = "$FAILPATH" ]; then
    echo "broken help for [$p]" >&2
    exit 3
  fi
  echo "usage: stub"
  exit 0
fi
STUB
    printf "cat <<'SCHEMA_EOF'\n%s\nSCHEMA_EOF\n" "$1"
  } >"$D/good"
  chmod +x "$D/good"
}
mkgood() { mkstub "$1" NONE; }   # never-failing variant

CANON='{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}'
ROOTONLY='{"groups":[],"commands":[]}'
# Which schema the mkcolor/mkempty/mkcrash fixtures bake in. Cases that assert a
# per-CONDITION property (color, empty stdout, crash markers) need only one path
# and set this to $ROOTONLY: probing three paths triples the process count to
# re-test the identical assertion. Cases that assert per-PATH coverage keep
# $CANON.
FIXTURE_SCHEMA=$CANON

# A target that emits an ANSI escape under exactly ONE of the four required
# color conditions, on a chosen stream. Without these, the mandatory has_ansi
# assertions are untested: a never-colored fixture passes whether or not the
# harness still checks for color, so deleting the ANSI gate stays green and the
# harness would certify a CLI that emits color everywhere.
mkcolor() { # mkcolor <plain|dumb|no_color_env|nocolor> <out|err>
  { echo '#!/bin/sh'
    echo "LOG='$LOG'"
    echo "WHEN='$1'"
    echo "STREAM='$2'"
    cat <<'STUB'
p=""; want=0; nc=0
for a in "$@"; do
  case $a in
    --help)     want=1 ;;
    --no-color) nc=1 ;;
    -*)         ;;
    *)          p="${p:+$p }$a" ;;
  esac
done
if [ "$want" -eq 1 ]; then
  if   [ "$nc" -eq 1 ];        then cond=nocolor
  elif [ -n "${NO_COLOR:-}" ]; then cond=no_color_env
  elif [ "${TERM:-}" = dumb ]; then cond=dumb
  else                              cond=plain
  fi
  printf 'help:[%s] cond=%s\n' "$p" "$cond" >>"$LOG"
  esc=$(printf '\033')
  if [ "$cond" = "$WHEN" ]; then
    if [ "$STREAM" = out ]; then
      printf '%s[31musage: colored%s[0m\n' "$esc" "$esc"
    else
      printf '%s[31mwarning%s[0m\n' "$esc" "$esc" >&2
      echo "usage: stub"
    fi
  else
    echo "usage: stub"
  fi
  exit 0
fi
STUB
    printf "cat <<'SCHEMA_EOF'\n%s\nSCHEMA_EOF\n" "$FIXTURE_SCHEMA"
  } >"$D/good"
  chmod +x "$D/good"
}

# A target that exits 0 for help but prints NOTHING on stdout — the classic
# "help went to stderr" defect. Nothing else about it is wrong, so only the
# non-empty-stdout assertion can fail the run.
mkempty() { # mkempty <out|err>
  { echo '#!/bin/sh'
    echo "LOG='$LOG'"
    echo "WHERE='$1'"
    cat <<'STUB'
p=""; want=0
for a in "$@"; do
  case $a in --help) want=1 ;; -*) ;; *) p="${p:+$p }$a" ;; esac
done
if [ "$want" -eq 1 ]; then
  printf 'help:[%s]\n' "$p" >>"$LOG"
  [ "$WHERE" = err ] && echo "usage: stub" >&2
  exit 0
fi
STUB
    printf "cat <<'SCHEMA_EOF'\n%s\nSCHEMA_EOF\n" "$FIXTURE_SCHEMA"
  } >"$D/good"
  chmod +x "$D/good"
}

# A target whose help is otherwise perfect — exit 0, non-empty stdout, no ANSI —
# but which leaks a crash marker. Only the crash assertion can fail the run.
mkcrash() { # mkcrash <marker> <out|err>
  { echo '#!/bin/sh'
    echo "LOG='$LOG'"
    # Heredoc, not MARKER='$1': the marker is free text and may contain single
    # quotes, which would terminate the assignment and emit a syntactically
    # broken stub. That failure surfaced as a bogus probe failure against a
    # perfectly good harness.
    # shellcheck disable=SC2016  # writing shell source; the $( ) is the stub's
    printf 'MARKER=$(cat <<%s\n%s\n%s\n)\n' "'MARKER_EOF'" "$1" "MARKER_EOF"
    echo "STREAM='$2'"
    cat <<'STUB'
p=""; want=0
for a in "$@"; do
  case $a in --help) want=1 ;; -*) ;; *) p="${p:+$p }$a" ;; esac
done
if [ "$want" -eq 1 ]; then
  printf 'help:[%s]\n' "$p" >>"$LOG"
  echo "usage: stub"
  if [ "$STREAM" = out ]; then echo "$MARKER"; else echo "$MARKER" >&2; fi
  exit 0
fi
STUB
    printf "cat <<'SCHEMA_EOF'\n%s\nSCHEMA_EOF\n" "$FIXTURE_SCHEMA"
  } >"$D/good"
  chmod +x "$D/good"
}

# A target that accepts --no-color everywhere EXCEPT the one documented,
# pass/fail placement `<path> --no-color --help`. Pins that the required
# invocation is actually made and actually asserted.
mkrejects_required_nocolor() {
  { echo '#!/bin/sh'
    echo "LOG='$LOG'"
    cat <<'STUB'
case " $* " in
  *" --no-color --help "*)
    echo "unsupported flag position" >&2
    printf 'reject:[%s]\n' "$*" >>"$LOG"
    exit 2 ;;
esac
for a in "$@"; do
  if [ "$a" = "--help" ]; then echo "usage: stub"; exit 0; fi
done
STUB
    printf "cat <<'SCHEMA_EOF'\n%s\nSCHEMA_EOF\n" "$FIXTURE_SCHEMA"
  } >"$D/good"
  chmod +x "$D/good"
}

chk() { # chk <name> <want-exit> <cmd...>
  name=$1 want=$2; shift 2
  : >"$LOG"
  out=$(timeout -k 2s 15s "$@" 2>&1); got=$?
  if [ "$got" -eq "$want" ]; then PASS=$((PASS+1)); printf 'ok   %s\n' "$name"
  else FAIL=$((FAIL+1)); printf 'FAIL %s (want exit %s, got %s)\n%s\n' "$name" "$want" "$got" "$out"
  fi
  LAST=$out
}

# Assert on what the TARGET recorded, never on probe.sh's own output.
probed() { # probed <path>
  if grep -qxF "help:[$1]" "$LOG"; then printf '     (target invoked [%s])\n' "$1"
  else printf '     TARGET NEVER INVOKED FOR [%s]\n' "$1"; FAIL=$((FAIL+1)); fi
}
not_probed() { # not_probed <path>
  if grep -qxF "help:[$1]" "$LOG"; then printf '     UNEXPECTED invocation [%s]\n' "$1"; FAIL=$((FAIL+1))
  else printf '     (no invocation for [%s], as expected)\n' "$1"; fi
}
said() { # said <substring>
  case $LAST in *"$1"*) ;; *) printf '     MISSING from output: %s\n' "$1"; FAIL=$((FAIL+1));; esac
}
logged() { # logged <substring of a target-written log line>
  if grep -qF "$1" "$LOG"; then printf '     (target saw %s)\n' "$1"
  else printf '     TARGET NEVER SAW %s\n' "$1"; FAIL=$((FAIL+1)); fi
}

echo "--- BLOCKER: deadline validation is fail-closed (exit 2, no hang) ---"
for v in 0 -1 bogus 1.5 '  ' 'x1'; do
  chk "DEADLINE='$v' -> exit 2" 2 env BIN="$D/stubborn" DEADLINE="$v" KILL_GRACE=1 sh "$P"
  chk "KILL_GRACE='$v' -> exit 2" 2 env BIN="$D/stubborn" DEADLINE=1 KILL_GRACE="$v" sh "$P"
done
# Sanity: a valid deadline against the TERM-ignoring target must still terminate
# and be reported as a target timeout (exit 1), never as a hang.
chk "valid deadline kills a TERM-ignoring target" 1 \
  env BIN="$D/stubborn" DEADLINE=1 KILL_GRACE=1 sh "$P"
case $LAST in *"timed out"*) echo "     (reported as timeout)";; *) echo "     unexpected: $LAST"; FAIL=$((FAIL+1));; esac

echo "--- NIT: token grammar rejects what the shell cannot carry ---"
# Each document below must be structurally valid EXCEPT for the token under
# test — hence the explicit "groups":[]. Omitting it made the required-array
# predicate supply the failure instead, so these cases passed while proving
# nothing about token_ok: relaxing token_ok to accept every string left the
# whole suite green.
for bad in '"db mi grate"' '"*"' '"db*"' '"-flag"' '"a?b"' '"x[1]"' '"a b"' '"."'; do
  mkgood "{\"groups\":[],\"commands\":[{\"path\":[$bad]}]}"
  chk "commands token $bad rejected" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
  said "not a valid command tree"
  not_probed "$(printf %s "$bad" | tr -d '"')"
  # The same grammar must be enforced on the groups array, not just commands.
  mkgood "{\"groups\":[{\"path\":[$bad]}],\"commands\":[]}"
  chk "groups token $bad rejected" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
  said "not a valid command tree"
  not_probed "$(printf %s "$bad" | tr -d '"')"
done
# The other path_ok branches, each otherwise structurally valid.
for badpath in '{}' '{"path":"db"}' '{"path":[]}' '{"path":[null]}' '{"path":[1]}'; do
  mkgood "{\"groups\":[],\"commands\":[$badpath]}"
  chk "malformed command entry $badpath rejected" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
  said "not a valid command tree"
done
mkgood '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}'
chk "ordinary tokens accepted" 0 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
probed ""; probed "db"; probed "db migrate"

echo "--- MANIFEST tokens obey the same grammar as schema tokens ---"
mkgood '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}'
for bad in '*' '?' 'x[1]' '-flag' 'db/migrate' 'db;rm'; do
  printf 'group db\ncommand db migrate\ncommand %s\n' "$bad" >"$D/mbad"
  chk "MANIFEST token '$bad' is exit 2, not a target failure" 2 \
    env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/mbad" SCHEMA_ARGS=schema sh "$P" --all
  said "outside the probe grammar"
done
# Irregular whitespace must CANONICALIZE, not fabricate a mismatch. Before
# normalization `db  migrate` compared unequal to the schema's `db migrate` and
# reported it as both missing and unknown.
printf '  group   db \ncommand\tdb\t\tmigrate\n\n' >"$D/mws"
chk "irregular whitespace canonicalizes, no false mismatch" 0 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/mws" SCHEMA_ARGS=schema sh "$P" --all
probed "db migrate"; not_probed "db  migrate"

echo "--- r4 regressions still fixed ---"
mkgood '{"groups":[],"commands":[{"path":["db","migrate"]}]}'
chk "omitted group is a FAIL and is probed anyway" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
said "schema omits group node"
probed "db"
mkgood '{"groups":[],"commands":[]}'
chk "root-only schema passes" 0 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
probed ""

echo "--- coverage is real: a broken path must fail even with a consistent schema ---"
# Root is not special-cased away. Dropping root from the probe set makes --all
# perform ZERO probes for a root-only schema; without this case that mutation
# stays green.
mkstub '{"groups":[],"commands":[]}' ''
chk "broken ROOT help fails a root-only run" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
probed ""; said "exit status 3"
# The schema here is fully self-consistent, so no mismatch can supply the
# failure — only actually probing `db --help` can.
mkstub '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}' 'db'
chk "broken GROUP help fails despite a consistent schema" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
probed "db"; probed "db migrate"; said "exit status 3"
mkstub '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}' 'db migrate'
chk "broken LEAF help fails despite a consistent schema" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
probed "db migrate"; said "exit status 3"

echo "--- the ANSI gate is real: color under ANY required condition must fail ---"
# label-for-condition: these are the four assert_help labels in probe.sh.
FIXTURE_SCHEMA=$ROOTONLY   # one path is enough: the assertion is per-condition
for spec in 'plain|non-tty' 'dumb|TERM=dumb' 'no_color_env|NO_COLOR' 'nocolor|--no-color'; do
  cond=${spec%|*}; label=${spec#*|}
  for stream in out err; do
    mkcolor "$cond" "$stream"
    chk "ANSI on std$stream under '$label' fails" 1 \
      env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
    said "$label: ANSI escapes on std$stream"
    logged "cond=$cond"
  done
done
# All four required conditions must actually be exercised, on every path.
FIXTURE_SCHEMA=$CANON
mkcolor none out
chk "every required color condition is exercised on every path" 0 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
for path in "" "db" "db migrate"; do
  for cond in plain dumb no_color_env nocolor; do logged "help:[$path] cond=$cond"; done
done
# The documented pass/fail placement must be the one that is required.
mkrejects_required_nocolor
chk "rejecting '<path> --no-color --help' fails the run" 1 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
said "--no-color: exit status 2"

echo "--- the rest of the full assertion set is pinned too ---"
# Every ordinary fixture satisfies these, so their passing is no evidence the
# assertions still exist. Each case below can only fail via the one assertion
# it targets: status is 0, stdout carries no ANSI, and nothing times out.
FIXTURE_SCHEMA=$ROOTONLY   # per-condition again, not per-path
for where in out err; do
  mkempty "$where"
  chk "empty stdout fails (help on std$where)" 1 \
    env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
  said "stdout empty"
  probed ""
done
# Crash-like text is ADVISORY: it must report and must NOT fail the run. A word
# list cannot decide whether a wrapper crashed, so the exit status must never
# depend on one. These cases pin both halves — the note appears, exit stays 0.
for marker in 'Traceback (most recent call last):' 'panic: runtime error' \
              'unhandled exception' "thread 'main' panicked at src/main.rs:4" \
              'Exception in thread "main" java.lang.NullPointerException' \
              'ReferenceError: x is not defined'; do
  mkcrash "$marker" err
  chk "crash-like stderr is advisory, not a failure ($(printf %.18s "$marker")…)" 0 \
    env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
  said "crash-like text on stderr"
  probed ""
  # The same words in help PROSE on stdout are not even worth a note.
  mkcrash "$marker" out
  chk "help documenting '$(printf %.16s "$marker")…' on stdout passes" 0 \
    env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
  probed ""
done
# A genuine crash is caught objectively, by status — not by its wording.
mkcrash 'something exploded in a way no word list anticipates' err
chk "unrecognised crash wording still passes when status is 0" 0 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
mkstub "$ROOTONLY" ''
chk "a real crash fails on exit status regardless of wording" 1 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
said "exit status 3"
FIXTURE_SCHEMA=$CANON

echo "--- both node arrays are required, empty is not the same as absent ---"
mkgood '{"commands":[]}'
chk "missing .groups is an invalid schema" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
said "not a valid command tree"
mkgood '{"groups":"nope","commands":[]}'
chk "non-array .groups is an invalid schema" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
said "not a valid command tree"
mkgood '{"groups":[]}'
chk "missing .commands is an invalid schema" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
said "not a valid command tree"

echo "--- a declared group with no leaf is legal, not a target failure ---"
mkgood '{"groups":[{"path":["empty"]}],"commands":[]}'
chk "empty group passes and is probed" 0 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
probed ""; probed "empty"
printf 'group empty\n' >"$D/me"
chk "empty group passes with a matching manifest" 0 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/me" SCHEMA_ARGS=schema sh "$P" --all
probed "empty"
# A path that is both a command and a group must not be double-reported.
mkgood '{"groups":[{"path":["db"]},{"path":["db","migrate"]}],"commands":[{"path":["db","migrate"]}]}'
chk "dual command/group path passes" 0 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
probed "db migrate"
# But a group the leaves DO imply, and the schema omits, is still a failure.
mkgood '{"groups":[],"commands":[{"path":["db","migrate"]}]}'
chk "omitted implied group is still a failure" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
said "schema omits group node"

echo "--- WARN: MANIFEST cross-check ---"
printf 'group db\ncommand db migrate\ncommand db backup\n' >"$D/m"
mkgood '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}'
chk "manifest catches a schema-hidden leaf" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/m" SCHEMA_ARGS=schema sh "$P" --all
said "schema omits command node(s) registered in source: db backup"
probed "db backup"
# ...and the hidden path is not merely listed: a manifest-only path whose help
# is broken must fail the run.
mkstub '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}' 'db backup'
chk "broken help on a manifest-only path fails the run" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/m" SCHEMA_ARGS=schema sh "$P" --all
probed "db backup"; said "exit status 3"
# The OTHER direction: a path the schema declares but source does not register.
# Without this, deleting the `unknown` half of the comparison left the suite
# green, so a schema could invent commands absent from source and still pass.
printf 'group db\ncommand db migrate\n' >"$D/mrev"
mkgood '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]},{"path":["db","backup"]}]}'
chk "manifest catches a schema-invented path" 1 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/mrev" SCHEMA_ARGS=schema sh "$P" --all
said "schema declares command node(s) not registered in source: db backup"
probed "db backup"

# Kind swaps: the paths match exactly, so an UNTYPED manifest passes these.
# They are the declaration error the nesting rule exists to catch.
printf 'command db\ncommand db migrate\n' >"$D/mkind1"
mkgood '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}'
chk "source leaf advertised as a schema group fails" 1 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/mkind1" SCHEMA_ARGS=schema sh "$P" --all
said "schema declares group node(s) not registered in source: db"
said "schema omits command node(s) registered in source: db"
printf 'group db\ngroup db migrate\n' >"$D/mkind2"
chk "source group advertised as a schema leaf fails" 1 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/mkind2" SCHEMA_ARGS=schema sh "$P" --all
said "schema omits group node(s) registered in source: db migrate"
said "schema declares command node(s) not registered in source: db migrate"
# A genuine dual-role path is legal — declared under both kinds on both sides.
printf 'group db\ngroup db migrate\ncommand db migrate\n' >"$D/mdual"
mkgood '{"groups":[{"path":["db"]},{"path":["db","migrate"]}],"commands":[{"path":["db","migrate"]}]}'
chk "dual-role path passes when declared under both kinds" 0 \
  env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/mdual" SCHEMA_ARGS=schema sh "$P" --all
probed "db migrate"
# Malformed kinds are harness misconfiguration, not target failures.
mkgood "$CANON"
for badline in 'db migrate' 'leaf db migrate' 'group' 'Group db'; do
  printf 'group db\ncommand db migrate\n%s\n' "$badline" >"$D/mkbad"
  chk "MANIFEST line '$badline' is exit 2" 2 \
    env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/mkbad" SCHEMA_ARGS=schema sh "$P" --all
done

printf 'command db migrate\ngroup db\n' >"$D/m2"
mkgood '{"groups":[{"path":["db"]}],"commands":[{"path":["db","migrate"]}]}'
chk "matching manifest passes" 0 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/m2" SCHEMA_ARGS=schema sh "$P" --all
probed ""; probed "db"; probed "db migrate"
mkgood '{"groups":[],"commands":[]}'
chk "unreadable MANIFEST is exit 2, not a target failure" 2 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 MANIFEST="$D/nope" SCHEMA_ARGS=schema sh "$P" --all
chk "coverage caveat printed without MANIFEST" 0 env BIN="$D/good" DEADLINE=5 KILL_GRACE=1 SCHEMA_ARGS=schema sh "$P" --all
said "cannot prove the schema is COMPLETE"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
