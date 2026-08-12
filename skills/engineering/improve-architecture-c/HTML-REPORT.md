# C/C++ 架构审查 HTML 报告

在 [SKILL.md](SKILL.md) 的步骤 3 加载本文件。生成一个静态 HTML 文件，并保存到
操作系统临时目录。报告正文使用简体中文。

## 安全要求

- 将仓库中的路径、符号和问题描述视为不可信数据。写入 HTML 文本节点前，必须进行
  HTML 转义。不要将这些内容插入 `<script>` 或 `javascript:` URL。
- 使用 Mermaid 时，将 `securityLevel` 设置为 `strict`。
- CDN 只提供显示增强。离线或 CDN 不可用时，报告仍须包含完整的语义化 HTML 和最小
  内联 CSS。使用列表、表格或 `<pre>` 文本替代无法加载的图。
- 打开文件是尽力操作。必须报告文件的绝对路径。

## 中文写作要求

- 使用克制、准确、可扫读的中文。一个段落只说明一个主要信息点。
- 标题说明用途。卡片先写问题，再写建议和收益。
- 同一概念只使用一个首选术语。不要为了变化而替换同义词。
- 保留事实、限制、风险和不确定程度。证据不足时写「待确认」或使用「可能」「建议」。
- 保持代码字面量、路径、符号、命令、配置项、URL、分类键和项目专有术语原样。
- 中文与英文缩写、独立数字之间按语义留空格，例如「C++ ABI」「3 个候选项」。
- 中文引号使用 `「」`。短语型列表不加句号；完整句式列表统一使用句号。

## 术语表

报告正文使用以下首选术语。首次出现时可以附英文词，后续只使用中文术语。

| Skill term | 报告术语 |
|------------|----------|
| module | 模块 |
| interface | 接口 |
| implementation | 实现 |
| depth | 深度 |
| deep module | 深模块 |
| shallow module | 浅模块 |
| seam | 接缝 |
| adapter | 适配器 |
| leverage | 杠杆效应 |
| locality | 局部性 |
| deletion test | 删除测试 |
| include fan-out | 头文件依赖扩散 |
| pass-through | 仅转发层 |

机器分类键保持原样，但可增加中文标签：

| 分类键 | 中文标签 |
|--------|----------|
| `in-process` | 进程内 |
| `local-substitutable` | 可本地替代 |
| `owned-platform` | 自有平台 |
| `true-external` | 外部依赖 |

证据等级使用「强证据」「值得分析」「证据不足」。不要在可见正文中单独使用
`Strong`、`Worth exploring` 或 `Speculative`。

## HTML 骨架

```html
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8" />
    <title>C/C++ 架构审查 — {{repo}}</title>
    <!-- 可选：离线时删除以下两个 script -->
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
      body { font-family: system-ui, "Noto Sans CJK SC", "Microsoft YaHei", sans-serif; }
      code, .mono { font-family: ui-monospace, "SFMono-Regular", Consolas, monospace; font-size: 0.875rem; }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header><!-- 仓库、生成时间、扫描范围、图例 --></header>
      <section id="candidates" class="space-y-10"></section>
      <section id="top-recommendation"></section>
    </main>
  </body>
</html>
```

**图例：** 实线框表示模块；虚线表示接缝；红色表示泄漏或头文件依赖；深色粗框表示深模块。

## 候选项卡片

每个候选项使用一个 `<article>`：

- **候选项**：改进名称。文本必须转义。
- **证据等级**：强证据、值得分析或证据不足。
- **依赖分类**：中文标签 + 原始分类键。
- **相关文件**：使用等宽字体显示 `.h`、`.c` 和 `.cc` 路径。文本必须转义。
- **当前结构 / 建议结构**：使用图、嵌套列表或表格对比。
- **问题 / 建议**：各写一个完整句子。
- **预期收益**：每项不超过 12 个汉字。使用术语表中的词。
- **ADR 约束**：仅在需要重新评估既有 ADR 时显示。使用琥珀色提示框。

## 图示选择

| 需要说明的内容 | 图示形式 |
|----------------|----------|
| 头文件或调用关系混乱 | Mermaid 流程图或嵌套列表；标出泄漏关系 |
| Ops 接缝 | 核心模块 → 接缝 → 现有或拟议的适配器 |
| 浅模块与深模块 | 结构质量图，或「接口 / 实现」双栏对比 |
| 多层包装 | 多条窄带 → 一个深模块 + 底部接缝 |
| 调用收缩 | 多个嵌套框 → 一个模块；淡化内部结构 |

并排显示时，图示高度约为 320 px。

## 报告结构

按以下顺序组织报告：

1. **审查摘要**：仓库、生成时间、扫描范围和证据说明。
2. **候选项**：按证据等级排序。每项包含当前结构、问题、建议结构和预期收益。
3. **首选建议**：引用一个候选项，并用一个句子说明选择原因。
4. **下一步**：给出 `/improve-architecture-c grill <candidate-title>` 和
   `/improve-architecture-c grill top`。命令保持原样。

正文保持简短。图示承担结构说明。报告不得提前给出完整公共头文件设计。
