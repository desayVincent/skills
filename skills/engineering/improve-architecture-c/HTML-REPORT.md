# HTML report (C/C++)

Load in step 3 of [SKILL.md](SKILL.md). One static file in OS temp — never the
repo.

## Safety

- Treat all repo-derived text (paths, symbols, problem sentences) as **untrusted
  data**: HTML-escape when embedding in HTML text nodes; never interpolate into
  `<script>` or raw `javascript:` URLs.
- Prefer **Mermaid `securityLevel: "strict"`** when using Mermaid.
- CDN (Tailwind/Mermaid) is optional enhancement. **Offline / no CDN:** still
  ship a complete readable report with semantic HTML + minimal inline CSS (cards,
  badges, before/after as nested lists or simple tables). Diagrams may be
  ASCII/pre blocks if Mermaid cannot load.
- Opening the file is **best-effort**; reporting the absolute path is mandatory.

## Scaffold (with optional CDN)

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review (C/C++) — {{repo}}</title>
    <!-- Optional: omit these two scripts when offline -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "strict" });
    </script>
    <style>
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      article { border: 1px solid #e7e5e4; border-radius: 0.5rem; padding: 1rem; margin: 1rem 0; }
      .badge { display: inline-block; padding: 0.1rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; }
      .strong { background: #d1fae5; }
      .worth { background: #fef3c7; }
      .spec { background: #e2e8f0; }
      code, .mono { font-family: ui-monospace, monospace; font-size: 0.875rem; }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header><!-- repo, date, legend --></header>
      <section id="candidates" class="space-y-10"></section>
      <section id="top-recommendation"></section>
    </main>
  </body>
</html>
```

**Legend:** solid box = module · dashed = seam · red = leak/include · thick dark = deep.

## Candidate card

One `<article>` each:

- **Title** — deepening name (escaped text)
- **Badges** — strength + category (`in-process` | `local-substitutable` |
  `owned-platform` | `true-external`)
- **Files** — monospaced `.h` / `.c` / `.cc` (escaped)
- **Before / After** diagram
- **Problem** / **Solution** — one sentence each
- **Wins** — ≤6 words each, in glossary terms
- **ADR callout** — amber, only if reopening

## Diagram picks

| Need | Pattern |
|------|---------|
| Include / call mess | Mermaid flowchart (strict) or nested list; mark leaks |
| Ops seam | Core → seam → adapters (draw adapters that exist or are proposed) |
| Shallow vs deep | Mass diagram or two-column “surface vs body” |
| Wrapper stack | Cross-section bands → one thick deep band + bottom seam |
| Call collapse | Nested boxes → one box, internals faded |

Keep diagrams ~320px tall when side-by-side.

## Vocabulary in prose

**Use:** module, interface, implementation, depth, deep, shallow, seam,
adapter, leverage, locality.

**Wins examples:** *locality: protocol bugs in one module* · *leverage: one
interface, N callers* · *interface shrinks; ops absorb HAL*.

Sparse prose. Diagrams carry the weight. Top recommendation: one card, one
sentence why, anchor to the candidate.
