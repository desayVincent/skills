# Classify repo (Active Git Root + keywords)

## Primary: Active Git Root

For each file path:

1. Resolve the nearest git root (`git rev-parse --show-toplevel` from the file’s directory).
2. That directory is the **Active Git Root**.
3. Decide **Repo Kind**:

| Kind | When |
|------|------|
| **Nested Kernel/BSP** | Active Git Root is a nested repo under a larger Super SDK tree, **or** the root itself is a kernel/BSP tree (Linux, Zephyr, RT-Thread, dedicated BSP). |
| **Super SDK** | Active Git Root is the product/SDK top repo, and the file is **not** inside another nested kernel/BSP git root. |

Defaults:

- Nested Kernel/BSP → prefer **DRIVER**; interrupt/fast path → **HOT**.
- Super SDK → prefer **ORCH**; calls into kernel/BSP ABI → **BOUND**.

Never apply Super SDK defaults to files whose Active Git Root is the nested kernel.

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

## Completion record (template)

```
Active Git Root: <path>
Repo Kind: Super SDK | Nested Kernel/BSP
Platform: linux | zephyr | rt-thread | unknown
Keyword notes: <optional>
```
