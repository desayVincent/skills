# Classify repo (Active Git Root + keywords)

**Single home** for Repo Kind defaults, Path Class/CTX default matrix, and the
Classification record. Path Class and CTX **meanings**: [path-class.md](path-class.md).
EMBEDDED Deliver (SKILL.md), Step 5, and H2/H6 point here for the record.

## Primary: Active Git Root

For each file path:

1. Resolve the nearest git root (`git rev-parse --show-toplevel` from the file’s directory).
2. That directory is the **Active Git Root**.
3. Decide **Repo Kind**:

| Kind | When |
|------|------|
| **Nested Kernel/BSP** | Active Git Root is a nested repo under a larger Super SDK tree, **or** the root itself is a kernel/BSP tree (Linux, Zephyr, RT-Thread, dedicated BSP). |
| **Super SDK** | Active Git Root is the product/SDK top repo, and the file is **not** inside another nested kernel/BSP git root. |

Never apply Super SDK defaults to files whose Active Git Root is the nested kernel.

## Default Path Class and CTX

| Repo Kind | Typical region | Default Path | Default CTX |
|-----------|----------------|--------------|-------------|
| Nested Kernel/BSP | IRQ handler / fast path | HOT | ISR |
| Nested Kernel/BSP | probe/init | ORCH or DRIVER | Init |
| Nested Kernel/BSP | normal driver ops | DRIVER | Thread |
| Super SDK | middleware, API, samples | ORCH | Thread / Init |
| Super SDK | glue calling kernel/BSP ABI | BOUND | Thread |
| Super SDK | kernel-private includes in SDK tree | — | fix structure |

Kind-level shortcuts when the region is unclear: Nested Kernel/BSP → **DRIVER**
(interrupt/fast → **HOT**); Super SDK → **ORCH** (kernel/BSP ABI call → **BOUND**).

## Secondary: Keyword Heuristic

Use path and tree tokens only to **corroborate** platform and to **prompt** when git metadata is missing:

| Tokens (examples) | Suggests platform appendix |
|-------------------|---------------------------|
| `linux`, `drivers/`, `Kconfig`, `include/linux` | linux |
| `zephyr`, `Kconfig.zephyr`, `zephyr/include` | zephyr |
| `rt-thread`, `rtthread`, `rtconfig.h` | rt-thread |
| `bsp`, `board`, `soc` | BSP (pair with OS tokens) |

Rules:

1. Keywords pick **which L1 appendix** to load when Root is Nested Kernel/BSP.
2. If nested `.git` is missing but keywords strongly match a kernel tree → **ask the user** before DRIVER/HOT defaults.
3. If Active Git Root says Super SDK but path looks like `docs/linux-integration` → **Root wins** (stay ORCH), do not switch to DRIVER.
4. Keywords alone never override a clear Nested Kernel/BSP root.

## Classification record (template)

### Region scope (minimal, fail bloat)

- Emit blocks only for **regions you edit or review** (entry points / callbacks /
  coherent hunks in the diff). Do **not** invent a block for an unchanged tree
  helper you only *call* (e.g. existing drop stats, logging, shared library).
- **One block per distinct (Path Class × CTX)** among those regions — not one
  block per function when several share the same class and context.
- Prefer the **smallest** set that still separates mixed Path/CTX (e.g. IRQ +
  Deferred + Thread → typically **3** blocks, not 5+).

**Multi-region gate:** mixed Path Class or CTX under one blanket class **fails**.
**Anti-bloat:** extra blocks that do not correspond to edited/reviewed code, or
duplicate the same Path×CTX without a distinct entry path, are **noise** (trim them).

### HOT call notes field

- Path Class **HOT:** field is **mandatory** — `none` or
  `call site → why not deferred / latency bound source` lines. Omitted ⇒ H2/H6
  **fail**.
- Path Class **not HOT:** **omit** the field entirely. Do **not** write
  `n/a`, `none`, or filler notes on non-HOT blocks.

```
Branch: HOST | EMBEDDED
Active Git Root: <path>
Repo Kind: Super SDK | Nested Kernel/BSP
Platform: linux | zephyr | rt-thread | bare-metal | unknown
Path Class: ORCH | HOT | BOUND | DRIVER
Execution Context (CTX): ISR | Deferred | Thread | Init | N/A
Governing rules: <tree style / Kconfig owner / ABI — short; file paths OK>
Keyword notes: <optional>
HOT call notes: <only if Path Class = HOT: none | call → reason lines>
```

**Done when:** required fields filled for each **edited or reviewed** region;
HOT blocks have valid `HOT call notes`; non-HOT blocks omit that field; no
bloat regions.
