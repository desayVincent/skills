> Human-facing provenance for write-legible-c rules (7etsuo, MIT).
> Not required for applying the standard to a C change. Do not treat as
> a substitute for repository-local evidence.

# Provenance

Every rule here either survived contact with working code or was taken from
a source that earned it. The sources, and the one thing each contributed:

- Gerard Holzmann, The Power of 10, NASA/JPL, 2006. Bounded loops, the
  recursion ban, the two-asserts-per-function density floor, smallest scope,
  and checking every return. Its ban on dynamic allocation after
  initialization is flight-software law, not general practice, and is not
  adopted. <https://spinroot.com/gerard/pdf/P10.pdf>
- G. Ann Campbell, Cognitive Complexity, SonarSource, 2017, revised 2023.
  The formal case for the depth cap: the metric charges each break in linear
  flow and charges nesting progressively with depth, and maintainers accepted
  its verdicts at a 77 percent rate in the field.
  <https://www.sonarsource.com/docs/CognitiveComplexity.pdf>
- Feitelson et al., identifier naming studies, ICPC line of work. Good names
  carry up to a 30 percent comprehension effect in humans. Names are the
  code's documentation.
- When Names Disappear, 2025, arXiv 2510.03178. Stripping identifiers
  degrades LLMs even on execution tasks that should depend only on structure.
  Naming is a first-class semantic channel for models, which is why section 3
  exists in its current strength.
- Li et al., What Builds Effective In-Context Examples for Code Generation,
  2025, arXiv 2508.06414. Models generate better against precise concise
  identifiers than verbose composites. Precision beats length, section 3.
- Rethinking Code Complexity Through the Lens of Large Language Models, 2026,
  arXiv 2602.07882. Model-perceived complexity, driven by semantic hierarchy
  depth and branching breadth, correlates strongly with task performance
  after controlling for code length, and semantics-preserving rewrites that
  reduce it improve downstream results by up to roughly 21 percent. The
  direct experimental support for this document's premise.
- Enhancing LLM-Based Code Generation with Complexity Metrics, 2025, arXiv
  2505.23953. Standard complexity metrics predict whether generated code
  passes, and complexity feedback improves regeneration. The reason section
  4 carries a numeric budget.
- The `AGENTS.md` convention, agents.md, plus 2026 field reports on agent
  one-shot task completion. The repository rules in [repository-level.md](repository-level.md).
- Kernighan and Pike, The Practice of Programming, 1999. The lineage:
  simplicity, clarity, generality, in that order.
- David Hanson, C Interfaces and Implementations, 1996. The
  module-as-interface discipline behind sections 1 and 7, and ownership
  stated at the interface.
- MISRA C and CERT C. Adopted in spirit: no reliance on undefined behavior,
  every warning an error. Rejected explicitly: the single-exit-point rule,
  because early returns are what keep cognitive complexity low and what
  `TRY` depends on.
