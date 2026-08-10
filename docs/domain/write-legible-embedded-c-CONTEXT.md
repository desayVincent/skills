---
title: "Context: Write-Legible Embedded C"
description: "write-legible-embedded-c 领域术语索引；规范正文在 skill 内。"
importance_tier: "normal"
contextType: "general"
---

# 领域上下文（索引）

**规范只在 skill 内。** 本文件是人类/agent 的术语索引，不重复 checklist、门禁或默认矩阵。改行为时只改右侧权威文件。

Skill 根目录：[`skills/engineering/write-legible-embedded-c/`](../../skills/engineering/write-legible-embedded-c/)

| 术语 | 权威位置 |
|---|---|
| 入口 / Hard Order / Deliver | [`SKILL.md`](../../skills/engineering/write-legible-embedded-c/SKILL.md) |
| Base Standard（vendored write-legible-c） | [`references/base/`](../../skills/engineering/write-legible-embedded-c/references/base/) |
| C Quality Floor | [`references/c-quality.md`](../../skills/engineering/write-legible-embedded-c/references/c-quality.md) |
| Active Git Root / Repo Kind / 默认 Path·CTX / Classification record | [`references/classify-repo.md`](../../skills/engineering/write-legible-embedded-c/references/classify-repo.md) |
| Path Class / Execution Context（含义） | [`references/path-class.md`](../../skills/engineering/write-legible-embedded-c/references/path-class.md) |
| HOT Rules (H1–H6) | [`references/hot-rules.md`](../../skills/engineering/write-legible-embedded-c/references/hot-rules.md) |
| Prior-contamination ban list (PC1–PC8) | [`references/concurrency-memory.md`](../../skills/engineering/write-legible-embedded-c/references/concurrency-memory.md) |
| L1 平台附录 | [`references/platforms/`](../../skills/engineering/write-legible-embedded-c/references/platforms/) |
| 打包决策 (ADR) | [`docs/adr/0001-base-plus-embedded-overlay-bundle.md`](../adr/0001-base-plus-embedded-overlay-bundle.md) |
| 归属 / 安装说明 | skill 内 `README.md`、`NOTICE` |

## 速查（无规则）

| 记号 | 一句话 |
|---|---|
| HOST / EMBEDDED | Step 0 二选一分支 |
| ORCH / HOT / BOUND / DRIVER | Path Class 四档 |
| ISR / Deferred / Thread / Init | Execution Context |
| Super SDK / Nested Kernel/BSP | Repo Kind |
| Constraint priority | 活树与契约 ≥ Quality floor + overlay ≥ Base 审美 |
