---
title: "Context: Write-Legible Embedded C"
description: "嵌入式 C 机读规范（覆盖 write-legible-c）的领域术语。"
importance_tier: "normal"
contextType: "general"
---

# 领域上下文

| 术语 | 本项目中的定义 |
|---|---|
| Base Standard | marketplace 安装的 `write-legible-c` 及其 `c-standard.md`；通用 C11 机读纪律，默认不修改上游正文。 |
| Embedded Overlay | 叠在 Base 之上的嵌入式规则；与 Base 同属 skill `write-legible-embedded-c`（HOST 调 Base，EMBEDDED 走 Hard Order）。Base 正文仍为 7etsuo 原作，置于 references/base/。 |
| HOST Deliver gate | HOST 交付 fail-closed：必须对最终 diff 逐项应用 Base `c-standard.md` §14（通过或源码点偏差注释）；仅有代码或「看起来干净」不算完成。模块有 status 枚举且编辑**非获取** orchestrator 时，按 Base §9 使用 `MODULE_TRY`/`FOO_TRY`（不新造协议；不用于获取函数或 HOT/IRQ）。见 SKILL.md Deliver → HOST。 |
| Constraint Priority | 规则冲突时的优先级：平台/实时/体积/冻结 SDK API ≥ Embedded Overlay ≥ Base Standard。偏差必须在源码偏差点注释说明约束。 |
| Execution Context | 代码运行的调度环境，跨 Linux / RT-Thread / Zephyr 统一抽象。取值：ISR、Deferred、Thread、Init。决定可睡性、锁/同步原语、能否阻塞。 |
| ISR | 硬中断或必须极短、通常不可睡眠的中断上下文（含需同等约束的上半部）。 |
| Deferred | 从中断延后的处理：tasklet、workqueue、softirq 下半、RTOS 延后任务等。 |
| Thread | 可调度线程上下文：用户线程、内核线程、RTOS 任务等（可否睡眠/加锁依具体平台与锁类型）。 |
| Init | 启动、模块初始化、BSP 上电/枚举序列等非热路径编排上下文。 |
| Path Class | 对本段代码施加哪套机读/legibility 规则。取值：ORCH、HOT、BOUND、DRIVER。 |
| ORCH | 编排档：Base Standard 全开（行数目标、orchestrator/leaf/adapter、status 等）。用于 init、状态机主流程、可调度业务逻辑。 |
| HOT | 热路径档：禁止仅为行数强拆；允许单 leaf 偏长；每个调用按时延、栈与上下文证明合理；仍约束嵌套、副作用与共享数据纪律。用于 ISR 与极紧 fast path。 |
| BOUND | 边界档：薄 adapter 对接冻结的 Vendor/SDK/内核公共 API；不重写对方实现。 |
| DRIVER | 驱动树档：宿主树风格优先（如 Linux kernel coding style、Zephyr 惯例）；Base Standard 作补充而非压过宿主。 |
| HOT Rules (H1–H6) | HOT 门禁：H1 关 Base 15/40；H2/H6 与 Classification 的 Path Class/CTX/HOT call notes **字段绑定（缺则失败）**；H3–H5 各一行决策，细节指向树与 concurrency ban list，不重讲驱动写法。 |
| Overlay Doc Layers | L0 = 分支/Hard Order/交付门禁 + H1–H6 字段耦合 + PC 禁区（**gate，非驱动教程**）；L1 = 平台**特有**所有权与验证（指针到树/并发/HOT，不重讲通用 ISR/锁课）。**Linux L1 仍可更深**；Zephyr/RT-Thread 更薄。L2 不进 skill。 |
| Classification record | 交付/审查时的唯一分类产物，模板在 `references/classify-repo.md`。必填 Branch、Active Git Root、Repo Kind、Platform、Path Class、CTX、Governing rules；HOT 时 **HOT call notes 必填**（`none` 或 `call → reason`），非 HOT **省略该字段**（禁止 `n/a` 填充）。仅覆盖**本次编辑**的 entry/hunk；按 Path×CTX 合并，禁止为未改 helper 滥增 region。Path/CTX 不同须多 region；缺 record 或字段 ⇒ fail-closed。 |
| Prior-contamination ban list | `concurrency-memory.md` 中 PC1–PC8 可勾选禁止项（自造 portable sync/reactor、`volatile` 当同步、ISR 堆分配/睡眠、无树依据的零调用教条、绕过 MMIO accessor、仅凭 common practice 选型等）；未全部通过则并发门禁失败。 |
| Super SDK Repo | 顶层大 git 仓库：产品/SDK 主体。工作树内可**嵌套**其它 git 仓库（子模块或嵌套 clone）。 |
| Nested Kernel/BSP Repo | 位于 Super SDK 工作树某路径下的嵌套 git 仓（如 Linux/BSP 路径）：内核、驱动、中断、线程、板级与硬件紧耦合代码。 |
| Repo Kind | 推断第一刀：当前文件落在**哪一个 Active Git Root**——在 Super SDK 根下且不在嵌套内核仓内 → SDK 姿态；在 Nested Kernel/BSP 根内 → 内核/BSP 姿态。 |
| Active Git Root | 当前文件所属的最近 git 根。默认 Path Class 与 L1 平台附录都相对该根选择，禁止用 Super SDK 根对嵌套内核树一刀切。为 Repo Kind 的**主信号**。 |
| Keyword Heuristic | 路径/树内关键词的**辅信号**（如 `linux`、`zephyr`、`rt-thread`、`drivers/`、`Kconfig`、`bsp`）。用于：印证 Active Git Root、在嵌套 `.git` 异常时提示、选择 L1 平台附录。**不得单独压过**明确的 Active Git Root；主辅冲突时以 Git Root 为准，或向用户确认。 |
| Skill Package | 团队用 **一个目录** `write-legible-embedded-c/` 进 git 与分发；内含 SKILL.md 与 references/base/（vendored write-legible-c）。无需再包一层 bundle。 |
| Attribution | 在 Bundle 的 README 中声明使用了 write-legible-c、来源仓库/作者、许可证与未修改/修改范围，以尊重原作者知识产权；不将 Base 宣称为自研正文。 |
| Hard Order | Agent 固定工作流：① Active Git Root + Keyword Heuristic → ② Repo Kind / Path Class / CTX 与局部树约束 → ③ 加载 Bundle 内 Base + Overlay L0 → ④ 按 Linux/Zephyr/RT-Thread 或实际 BSP 加载 L1/平台规则并确认构建、接口、并发与 MMIO 边界 → ⑤ 改代码 → ⑥ checklist（HOT 则含 H1–H6）。 |
