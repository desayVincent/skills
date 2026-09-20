# Agent DX CLI Scale — index

Full text (offline): [vendor/agent-dx-cli-scale/agent-dx-cli-scale.md](../vendor/agent-dx-cli-scale/agent-dx-cli-scale.md)

When scoring, use the vendor skill. This file is a compact copy of the same seven axes.

Score each axis 0–3. Sum is 0–21. A score of 2 or 3 requires a named command or flag as evidence.

## Axes

### 1. Machine-readable output

Can an agent parse output without heuristics?

| Score | Criteria |
|---|---|
| 0 | Human-only output. No structured format. |
| 1 | `--output json` or equivalent exists but is incomplete or inconsistent. |
| 2 | Consistent JSON across commands. Errors also structured JSON. |
| 3 | NDJSON for paginated results. Structured output default on non-TTY. |

### 2. Raw payload input

Can an agent send the full payload without flattening it into bespoke flags?

| Score | Criteria |
|---|---|
| 0 | Flags only. |
| 1 | `--json` or stdin JSON on some commands. |
| 2 | All mutating commands accept a raw JSON payload that maps to the real schema. |
| 3 | Raw payload is first-class beside convenience flags. Zero translation loss. |

### 3. Schema introspection

Can an agent discover the surface at runtime?

| Score | Criteria |
|---|---|
| 0 | Only `--help` text. |
| 1 | `--help --json` or `describe` on some surfaces. |
| 2 | Full JSON schema for all commands — params, types, required fields. |
| 3 | Live runtime-resolved schemas, including scopes, enums, nested types. |

### 4. Context window discipline

Can the agent bound what comes back?

| Score | Criteria |
|---|---|
| 0 | Full responses. No field limit, no pagination. |
| 1 | `--fields` or field masks on some commands. |
| 2 | Field masks on all reads. Pagination with a fetch-all switch. |
| 3 | Streaming pagination. Shipped skill tells the agent to use field masks. |

### 5. Input hardening

Does the CLI defend against agent hallucinations, not just typos?

| Score | Criteria |
|---|---|
| 0 | Basic type checks only. |
| 1 | Some validation, missing traversal / encoding / query-in-id cases. |
| 2 | Rejects control characters, `../`, `%`-encoded segments, embedded `?` `#` in ids. |
| 3 | Plus output-path sandboxing, HTTP-layer encoding, explicit untrusted-caller posture. |

### 6. Safety rails

Can the agent validate before acting?

| Score | Criteria |
|---|---|
| 0 | No dry-run. No response sanitization. |
| 1 | `--dry-run` on some mutating commands. |
| 2 | `--dry-run` on all mutating commands. |
| 3 | Dry-run plus response sanitization against prompt injection in returned data. |

### 7. Agent knowledge packaging

Does the CLI ship knowledge agents can load at session start?

| Score | Criteria |
|---|---|
| 0 | `--help` and a website. |
| 1 | `CONTEXT.md` or `AGENTS.md` with basic usage. |
| 2 | Structured skill files covering workflows and invariants. |
| 3 | Versioned skill library with guardrails (`always --dry-run`, `always --fields`). |

## Totals

| Range | Rating | Meaning |
|---|---|---|
| 0–5 | Human-only | Agents will parse poorly, hallucinate inputs, and lack rails. |
| 6–10 | Agent-tolerant | Usable with heavy prompting and token waste. |
| 11–15 | Agent-ready | Structured I/O and some introspection. Gaps remain. |
| 16–21 | Agent-first | Schema, hardening, rails, and packaged knowledge. |

## Unscored extras

Note, do not add to the total:

- MCP over stdio JSON-RPC
- Extension / plugin install so the agent treats the CLI as native
- Headless auth (env or token file, no browser redirect)

## Report shape

```
Axis                  Score  Evidence
1 Machine-readable      n    <command>
2 Raw payload           n    <command>
3 Schema                n    <command>
4 Context discipline    n    <command>
5 Input hardening       n    <command or test>
6 Safety rails          n    <command>
7 Knowledge packaging   n    <path>
Total                   /21  <rating>

Cheapest additive fixes, in order:
1. …
```
