> Disclosed reference from write-legible-c `c-standard` (7etsuo, MIT).
> Load only on the branch named in [write-legible-c-SKILL.md](write-legible-c-SKILL.md).
> Normative rules remain in [c-standard.md](c-standard.md) sections 1–14.

# The repository level

Function and file rules are half the job. Agents navigate repositories, and
the repository has its own legibility budget.

- An `AGENTS.md` at the repo root, under 150 lines, hand-written. It carries
  exactly what a capable stranger could not infer: build, test, and lint
  commands, the boundaries an agent must not cross, and the two or three
  architectural decisions that look wrong from outside but are intentional.
  Keep it short; a section earns its place only after an agent has
  repeatedly gotten that thing wrong.
- Resolve either-or conventions with decision tables. When the codebase
  sanctions two ways to do a thing, a table choosing per situation beats
  prose and measurably improves convention adherence.
- Include a few short examples lifted from the real codebase, three to ten
  lines each. Agents pattern-match, so hand them the right pattern. More than
  a handful and they start matching the wrong thing.
- Describe capabilities and shape, not file paths. Paths rot, and a
  confidently wrong map is worse than none. Per-directory purpose lives in a
  one-paragraph README inside that directory, which agents read first when
  they list it.
- A nested `AGENTS.md` per package carries anything package-specific.
- The test suite is the agent's feedback loop. An agent works autonomously
  exactly as far as the tests can verify; past that point every change routes
  through a human. Tests are part of the readability story, not separate from
  it.
- Verbosity is a tax on context. Everything an agent must read to act
  competes with the task itself for the same window. Density of signal is a
  repository property, and this whole document is in its service.

