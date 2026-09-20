#!/bin/sh
# probe.sh — agent-readiness probes for a CLI's help surface.
#
# Usage:
#   BIN=./yourcli sh probe.sh                 # probe root help only
#   BIN=./yourcli sh probe.sh db migrate      # probe one command path
#   BIN=./yourcli sh probe.sh --all           # enumerate from schema, probe each path
#   BIN=./yourcli MANIFEST=paths.txt sh probe.sh --all   # + cross-check vs source
#
# Env:
#   BIN          the CLI under test (required)
#   DEADLINE     seconds before a probe is considered hung (default 10).
#                Positive whole seconds only — 0 means "no timeout" to timeout(1).
#   KILL_GRACE   seconds between TERM and KILL (default 2). Same grammar.
#   SCHEMA_ARGS  how to ask the CLI for its schema (default "schema --format=json")
#   MANIFEST     optional file of source-derived paths, one per line, typed:
#                  group   db
#                  command db migrate
#                Kinds are compared separately, so a schema that advertises a
#                leaf as a group (or vice versa) fails. A genuinely dual-role
#                path must appear under both kinds.
#
# Exit: 0 all probes passed, 1 a probe failed, 2 harness misconfiguration.
#
# The harness is FAIL-CLOSED: if it cannot guarantee a hard-kill deadline, or a
# required tool is missing, it exits 2 rather than running a weaker test whose
# PASS would not mean what it says.
#
# Scope: mechanically checkable invariants only — help exit status, stream
# separation, hang detection, environment independence, and the color matrix.
# Items marked "manual" in audit-checklist.md are NOT covered here; never report
# them as probe-backed.

# -f (noglob) is load-bearing, not tidiness. Command paths are carried as
# space-joined lines and re-split by word splitting at the probe call, which
# would otherwise also pathname-expand: a path token of `*` would silently
# become the caller's directory listing and probe argv nobody wrote. Token
# grammars below reject such tokens outright; -f means a gap in that validation
# cannot turn into a wrong invocation.
set -uf

: "${BIN:?set BIN to the CLI under test}"
: "${DEADLINE:=10}"
: "${KILL_GRACE:=2}"
: "${SCHEMA_ARGS:=schema --format=json}"

die2() { echo "harness: $1" >&2; exit 2; }

# --- the deadline itself is a prerequisite -----------------------------------
# The whole fail-closed guarantee reduces to these two numbers, and `timeout`
# documents a duration of 0 as *disabling* that timeout: DEADLINE=0 removes the
# TERM deadline, KILL_GRACE=0 removes the KILL escalation, and either one
# silently restores the unbounded hang this harness promises to refuse. A
# non-numeric value is worse than useless — `timeout` exits 125, which would be
# counted against the target as a probe failure rather than reported as our own
# misconfiguration. Validate before anything can run.
require_positive_seconds() {
  case "$2" in
    '' | *[!0-9]*)
      die2 "$1 must be a positive whole number of seconds (got '$2')" ;;
  esac
  [ "$2" -gt 0 ] \
    || die2 "$1 must be greater than 0: timeout(1) treats 0 as no timeout at all, which would defeat the hard-kill deadline"
}
require_positive_seconds DEADLINE "$DEADLINE"
require_positive_seconds KILL_GRACE "$KILL_GRACE"

# --- prerequisites: a missing tool is OUR misconfiguration, not a CLI defect ---
command -v timeout >/dev/null 2>&1 || die2 "timeout(1) not found"
# A plain `timeout N` sends TERM only; a CLI that traps TERM would hang the probe
# forever. Without -k there is no hard deadline, so refuse to run.
timeout -k 1 1 true >/dev/null 2>&1 \
  || die2 "timeout(1) lacks -k, so no hard-kill deadline is available; refusing to run an unbounded probe"

BIN=$(command -v "$BIN") || die2 "cannot resolve BIN"
case "$BIN" in /*) ;; *) BIN="$PWD/${BIN#./}" ;; esac
[ -x "$BIN" ] || die2 "not executable: $BIN"

WORK=$(mktemp -d) || die2 "cannot create temp dir"
trap 'rm -rf "$WORK"' EXIT
trap 'rm -rf "$WORK"; exit 130' INT TERM

TIMEOUT="timeout -k ${KILL_GRACE}s ${DEADLINE}s"
FAILS=0
MANIFEST_USED=0
ESC=$(printf '\033')

note() {
  printf '  %-5s %s\n' "$1" "$2"
  [ "$1" = FAIL ] && FAILS=$((FAILS + 1))
  return 0
}

has_ansi() { LC_ALL=C grep -q "$ESC" "$1" 2>/dev/null; }

# run_cli <extra-env> <args...> -> sets STATUS, writes $WORK/out and $WORK/err
run_cli() {
  extra=$1
  shift
  rm -rf "${WORK:?}/cwd" "${WORK:?}/home"
  mkdir -p "$WORK/cwd" "$WORK/home"
  STATUS=0
  # Empty cwd + minimal explicit env. Not `env -i` with nothing: most runtimes
  # need PATH and HOME to start at all, and stripping to zero reports failures
  # no real user would hit.
  # shellcheck disable=SC2086
  ( cd "$WORK/cwd" && exec env -i PATH="$PATH" HOME="$WORK/home" $extra \
      $TIMEOUT "$BIN" "$@" ) >"$WORK/out" 2>"$WORK/err" </dev/null || STATUS=$?
}

# assert_help <label> — the FULL assertion set, applied to every condition.
# Checking only ANSI under the color conditions lets a CLI that rejects
# --no-color (exit 2) pass clean — verified.
assert_help() {
  label=$1
  if [ "$STATUS" -eq 124 ] || [ "$STATUS" -eq 137 ]; then
    note FAIL "$label: timed out after ${DEADLINE}s (pager or prompt?)"
    return 0
  fi
  [ "$STATUS" -eq 0 ] || note FAIL "$label: exit status $STATUS (want 0)"
  [ -s "$WORK/out" ] || note FAIL "$label: stdout empty (help on stderr, or no help)"
  has_ansi "$WORK/out" && note FAIL "$label: ANSI escapes on stdout"
  has_ansi "$WORK/err" && note FAIL "$label: ANSI escapes on stderr"
  # ADVISORY, not an invariant — deliberately. A word list is not a crash
  # detector. Any fixed set has both boundaries wrong: it misses Rust's
  # `thread 'main' panicked at`, Java's `Exception in thread`, Node's
  # `ReferenceError:`, an uppercased or timestamp-prefixed variant; and it
  # flags a line-start explanatory message that merely uses the phrase. A real
  # crash is already caught objectively by the exit-status and empty-stdout
  # assertions above. What is left is the narrow case of a wrapper that leaks
  # crash-looking text yet still exits 0 — precisely where a generic word list
  # is least able to establish what happened.
  #
  # So it reports, and never fails. Being advisory is what lets the pattern set
  # be broad: a false positive costs a line of output, not a bad release gate.
  grep -qE "^[^[:alnum:]]*(Traceback \(most recent call last\):|panic: |[Uu]nhandled [Ee]xception|thread '[^']*' panicked at|Exception in thread|[A-Za-z]*Error: )" \
    "$WORK/err" 2>/dev/null \
    && note note "$label: crash-like text on stderr — heuristic, confirm by hand"
  return 0
}

probe_help() {
  if [ $# -eq 0 ]; then printf '\n%s --help\n' "$(basename "$BIN")"
  else printf '\n%s %s --help\n' "$(basename "$BIN")" "$*"
  fi

  # Four independent color requirements, each with the full assertion set.
  # Probing only TERM=dumb passes a CLI that emits ANSI in every other
  # condition — verified.
  run_cli "TERM=xterm-256color" "$@" --help
  assert_help "non-tty"
  [ "$STATUS" -eq 0 ] && [ -s "$WORK/out" ] && note ok "help on stdout, exit 0"
  [ -s "$WORK/err" ] && note WARN "wrote $(wc -c <"$WORK/err" | tr -d ' ') bytes to stderr"

  run_cli "TERM=dumb" "$@" --help
  assert_help "TERM=dumb"

  run_cli "TERM=xterm-256color NO_COLOR=1" "$@" --help
  assert_help "NO_COLOR"

  # Required position: after the command path (the canonical grammar) and before
  # --help, which conventionally short-circuits and ignores what follows.
  # Requiring a leading `--no-color <path> --help` would fail CLIs that only
  # accept the documented placement — a harness assumption, not a CLI defect.
  run_cli "TERM=xterm-256color" "$@" --no-color --help
  assert_help "--no-color"

  # Other placements are conventions, not invariants: warn, never fail.
  run_cli "TERM=xterm-256color" --no-color "$@" --help
  [ "$STATUS" -ne 0 ] && note WARN "--no-color rejected before the command path"
  run_cli "TERM=xterm-256color" "$@" --help --no-color
  if [ "$STATUS" -ne 0 ]; then
    note WARN "--no-color rejected after --help (order-dependent)"
  elif has_ansi "$WORK/out" || has_ansi "$WORK/err"; then
    note WARN "trailing --no-color ignored (ANSI still emitted)"
  fi
  return 0
}

# The one grammar every command token must satisfy, for schema and manifest
# alike: a leading alphanumeric, then alphanumerics, dot, underscore, hyphen.
# It excludes whitespace (which word splitting would turn into extra tokens),
# glob metacharacters, and a leading "-" (which the target would read as an
# option rather than a command).
token_ok() {
  case $1 in
    '' | [!A-Za-z0-9]* | *[!A-Za-z0-9._-]*) return 1 ;;
  esac
  return 0
}

# stdin:  `group <path>` or `command <path>` per line, tokens whitespace-separated.
# stdout: the same, one canonical `<kind> <single-spaced path>` per line.
normalize_manifest() {
  while IFS= read -r line || [ -n "$line" ]; do
    # Unquoted on purpose: field splitting collapses runs of spaces and tabs.
    # Safe only because `set -f` is in force, so no token can be globbed.
    # shellcheck disable=SC2086
    set -- $line
    [ $# -eq 0 ] && continue
    _kind=$1
    shift
    case $_kind in
      group | command) ;;
      *) die2 "MANIFEST line must begin with 'group' or 'command' (got '$_kind'; line: $line)" ;;
    esac
    [ $# -gt 0 ] || die2 "MANIFEST '$_kind' line has no path (line: $line)"
    _path=
    for _tok in "$@"; do
      token_ok "$_tok" \
        || die2 "MANIFEST token '$_tok' is outside the probe grammar [A-Za-z0-9][A-Za-z0-9._-]* (line: $line)"
      _path="${_path:+$_path }$_tok"
    done
    printf '%s %s\n' "$_kind" "$_path"
  done
}

enumerate() {
  command -v jq >/dev/null 2>&1 || die2 "jq not found, required for --all"
  # shellcheck disable=SC2086  # SCHEMA_ARGS is a command line, split intentionally
  run_cli "TERM=dumb" $SCHEMA_ARGS
  [ "$STATUS" -eq 0 ] \
    || { echo "harness: '$SCHEMA_ARGS' failed (status $STATUS); enumerate from source instead" >&2; return 1; }

  # One strict structural expression. `jq -e '.commands'` alone only tests
  # truthiness: "groups":"not-an-array" was accepted and its error suppressed.
  # BOTH node arrays are required, matching the discovery contract and the error
  # message below. An absent `.groups` is not the same fact as an empty one: a
  # root-only CLI states `"groups": []` deliberately, whereas a missing member
  # means the producer never emitted the collection, and silently reading it as
  # empty is how a truncated schema passes for a complete one.
  # Tokens are constrained to a grammar this harness can carry through a POSIX
  # shell without eval. Paths are flattened with join(" ") below and re-split by
  # word splitting, so a token containing whitespace would not be probed as the
  # schema wrote it, and a glob character would be pathname-expanded against the
  # cwd. Rejecting those as out-of-contract is honest; accepting them and
  # silently probing something else is not. A leading "-" is excluded too: it
  # would reach the target as an option, not a command.
  jq -e '
    def token_ok: type == "string" and test("^[A-Za-z0-9][A-Za-z0-9._-]*$");
    def path_ok:  has("path") and (.path | type == "array")
                  and (.path | length > 0) and (.path | all(token_ok));
    (type == "object")
    and (has("commands") and (.commands | type == "array"))
    and (has("groups") and (.groups | type == "array"))
    and (.commands | all(path_ok))
    and ((.groups // []) | all(path_ok))
  ' >/dev/null <"$WORK/out" \
    || { echo "harness: schema is not a valid command tree (need an object with array .commands/.groups, each entry a non-empty .path array of tokens matching [A-Za-z0-9][A-Za-z0-9._-]*)" >&2; return 1; }

  # Write paths only after validation, and never discard jq's errors.
  # Derive every proper prefix of every command path. A schema that simply omits
  # the group whose help is broken must not thereby skip probing it.
  jq -r '(.commands // [])[] | .path as $p | range(1; ($p | length)) | $p[0:.] | join(" ")' \
    <"$WORK/out" | grep . | sort -u >"$WORK/derived" || :
  jq -r '(.groups   // [])[] | .path | join(" ")' <"$WORK/out" | grep . | sort -u >"$WORK/declared" || :
  jq -r '(.commands // [])[] | .path | join(" ")' <"$WORK/out" | grep . | sort -u >"$WORK/leaves"   || :

  # A derived prefix that the schema fails to declare is a real defect: some
  # surviving leaf proves that group path exists and must have help. Report it,
  # then probe the union anyway so coverage does not depend on what the schema
  # chose to declare.
  #
  # The converse is NOT a defect. A declared group deriving from no leaf is a
  # perfectly legal help path — an empty plugin namespace, a group whose
  # commands are registered elsewhere, a path that is both command and group.
  # Nothing in this skill requires a group to own a leaf, and failing it here
  # made the release gate reject a CLI whose surface was entirely correct and
  # which an independent source manifest confirmed. Probe such groups like any
  # other; when MANIFEST is supplied the source comparison below decides whether
  # they are genuinely registered.
  missing=$(comm -13 "$WORK/declared" "$WORK/derived" | tr '\n' ',' | sed 's/,$//')
  [ -n "$missing" ] && note FAIL "schema omits group node(s) implied by command paths: $missing"

  cat "$WORK/derived" "$WORK/declared" "$WORK/leaves" | grep . | sort -u >"$WORK/union"

  # Completeness cannot be established from the schema alone, and this harness
  # must not imply otherwise. Deriving prefixes catches a missing *group*,
  # because some descendant leaf still names it — but a schema that omits a
  # leaf, or a group together with every one of its leaves, leaves no prefix to
  # derive and no mismatch to report. Validating a document against itself also
  # cannot tell a genuinely root-only CLI from a truncated schema: both present
  # as {"groups":[],"commands":[]}. Source registration is the only independent
  # evidence, so take it when the auditor can supply it.
  if [ -n "${MANIFEST:-}" ]; then
    [ -r "$MANIFEST" ] || die2 "MANIFEST not readable: $MANIFEST"
    # The manifest is a second, independent input to the same lossy transport,
    # so it gets the same contract as schema paths — not merely a trim. Without
    # canonicalization `db  migrate` would compare unequal to the schema's
    # `db migrate` and report BOTH a missing and an unknown path for a pair that
    # actually agrees; without token validation a `*` line would reach the
    # unquoted probe call. Malformed manifest content is the auditor's mistake,
    # so it is exit 2, never a probe failure charged to the target.
    # Redirect, never a pipe: in `normalize_manifest | sort` the function runs in
    # a subshell, so die2's exit 2 would kill only that subshell and the run
    # would continue against an empty manifest.
    #
    # The manifest is TYPED — `group <path>` / `command <path>` — because an
    # untyped path list cannot express the fact the nesting rule turns on. With
    # one flat set, a source leaf `db migrate` and a schema that advertises
    # `db migrate` as a *group* compare equal and PASS, which is exactly the
    # declaration error auditors are told to catch. Kinds are compared
    # independently; a genuine dual-role path must be declared in both.
    normalize_manifest <"$MANIFEST" >"$WORK/manifest.raw"
    for kind in group command; do
      sed -n "s/^$kind //p" "$WORK/manifest.raw" | sort -u >"$WORK/src.$kind"
    done
    sort -u "$WORK/src.group" "$WORK/src.command" >"$WORK/manifest"

    # declared groups vs source groups, leaves vs source leaves — separately.
    for pair in "declared:group:group" "leaves:command:command"; do
      have=${pair%%:*}; rest=${pair#*:}; src=${rest%%:*}; word=${rest#*:}
      a=$(comm -13 "$WORK/$have" "$WORK/src.$src" | tr '\n' ',' | sed 's/,$//')
      b=$(comm -23 "$WORK/$have" "$WORK/src.$src" | tr '\n' ',' | sed 's/,$//')
      [ -n "$a" ] && note FAIL "schema omits $word node(s) registered in source: $a"
      [ -n "$b" ] && note FAIL "schema declares $word node(s) not registered in source: $b"
    done
    # No separate kind-swap check is needed, and adding one is a bug: comparing
    # each kind independently already reports a swap from both sides (the schema
    # declares a group source never registered, AND omits the command source
    # did). An intersection test on top of that fires on a legitimately
    # dual-role path — declared under both kinds on both sides — and failed it.

    # Probe the union of both: a path only the manifest knows about is exactly
    # the one the schema was hiding, so it is the one that most needs probing.
    cat "$WORK/union" "$WORK/manifest" | grep . | sort -u >"$WORK/probeset"
    MANIFEST_USED=1
  else
    cp "$WORK/union" "$WORK/probeset"
  fi

  # Root first, then everything else. Zero children is legitimate — a root-only
  # CLI's complete surface is its root.
  printf '\n' >"$WORK/paths"
  cat "$WORK/probeset" >>"$WORK/paths"
  return 0
}

if [ "${1:-}" = "--all" ]; then
  enumerate || exit 1
  # Redirect, never a pipe: a `... | while read` loop runs in a subshell, so
  # FAILS would be discarded and an early failure masked by a later pass.
  while IFS= read -r p; do
    # shellcheck disable=SC2086
    probe_help $p
  done <"$WORK/paths"
  printf '\n'
  # Never let a PASS be read as "every path exists and was exercised".
  if [ "$MANIFEST_USED" -eq 1 ]; then
    echo "coverage: schema cross-checked against the source manifest; probed the union"
  else
    echo "coverage: probed the schema's declared leaves and their derived group"
    echo "          prefixes. This cannot prove the schema is COMPLETE — set"
    echo "          MANIFEST=<file of source-registered paths> to check that."
  fi
else
  probe_help "$@"
fi

printf '\n'
if [ "$FAILS" -eq 0 ]; then
  echo "PASS: no probe failures"
  exit 0
fi
echo "FAIL: $FAILS probe failure(s)"
exit 1
