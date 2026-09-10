# 上游版本、适配范围与验证证据

2026-09-10 获取以下仓库的完整浅克隆并核对本表材料。规则已经适配到本 skill 的文件；这些链接用于维护追溯，运行时不读取远程或调用上游 skill。许可全文见 [上游许可声明](UPSTREAM-LICENSES.md)，本 skill 原 LICENSE 保留。

| 来源 | 固定提交 | 已核对材料 |
| --- | --- | --- |
| [technical-writing](https://github.com/luoling8192/technical-writing/tree/5f684e950319bee8f773c3b5f5265c8bdda2900a) | `5f684e950319bee8f773c3b5f5265c8bdda2900a` | SKILL.md 全文、README、LICENSE；仓库文件清单 |
| [plain-writing](https://github.com/docwriter-org/plain-writing-skill/tree/f0d3630983ac7a82aa580f1c1509d72df739ee12) | `f0d3630983ac7a82aa580f1c1509d72df739ee12` | SKILL.md 全文，evals README、run_eval.py、write_readme.py、数据集与归属 |
| [blader/humanizer](https://github.com/blader/humanizer/tree/9862685f575c65a8247f90369951df1b3416e3d6) | `9862685f575c65a8247f90369951df1b3416e3d6` | SKILL.md 工作流与模式目录、README、包验证脚本及 LICENSE |
| [Aboudjem/humanizer-skill](https://github.com/Aboudjem/humanizer-skill/tree/a58df065367550b6ce40ff3f648335018d8e0589) | `a58df065367550b6ce40ff3f648335018d8e0589` | SKILL 模式及保真条款，实验性中文参考、evals.json、CLI README 和 LICENSE |

## 主体方法：technical-writing

| 上游方法 | 本地落点 | 适配 |
| --- | --- | --- |
| Core Stance / Evidence-First / 强判断先核查 | technical-polish 第 1、2 节 | 观察、推断、决定和状态分开；要求来源实际支持主张，重复猜想不算证据 |
| Preferred Structure / 读者问题 / 摘要 | technical-polish 第 1、3 节 | 以问题推进章节；摘要可结论先行，不强制三段或外部启发开头 |
| Module-Level Writing / 影响面 / eval | technical-polish 第 3、4 节 | 抽象边界连接具体实现与验证；没有证据不补造模块关系 |
| Language / Buzzword / Few-Shot 修复 | plain-language 全文 | 对象、动作、约束代替空评价和隐喻，不照搬仍含「很重要」的弱示例 |
| Lists, Quotes, Flow / Checklist | technical-polish 第 3、5 节及 ai-patterns | 表达形式服从信息关系；不强制 quote、mindmap、图或反问 |
| Tone Calibration | SKILL 保真边界与执行流程 | 平稳解释；保留原本确定程度，不统一添加「也许、暂时」 |

内部技术长文使用以上方法为主体；原 API、UI、操作入口仍保留适用边界，未把技术方案结构强加到这些内容。

## 表达方法：plain-writing 的 25 条规则

| 上游规则号 | 本地处理 |
| --- | --- |
| 1–4、6–7 | plain-language：常用词、必要术语、去空评价、稳定名称、避免发明标签 |
| 5 | 英语缩写习惯不移植为中文要求 |
| 8–10、13–14 | technical-polish 与 plain-language：清楚主干、实际时序、主题与支持、必要背景 |
| 11–12 | 保留不堆条件、不写碎片的目的；不采用固定从句数或偏好长句 |
| 15–18 | 术语与排版、ai-patterns：减少装饰；不全禁破折号、冒号或强制英语引号 |
| 19 | 按信息结构选择段落/列表/表格，不限制固定条数 |
| 20–23 | plain-language 与 ai-patterns：明确主体、解释实际机制、去假对比和反问；保留真实工具动作及必要对比 |
| 24–25 | 消除不清指代与空开场；不禁止明确代词、编号或有用数量概览 |
| deslopify | 改写入口直接交付结果，先结构后句段；不新增另一个用户命令 |

## 模式方法：humanizer

blader 的 staging、rhythm、inflation、formatting、leftovers 五组在 ai-patterns 中落实为 18 类人工检查；合并重复模式，技术重复、正式格式和真实不确定性保留。

Aboudjem 的 P1–P55 仅按技术适用性吸收：内容夸大/模糊归属、同义轮换、假范围、模板结构、聊天残留、占位/断链、未支持的因果及重复限定，对应 ai-patterns 与技术保真边界。符号及英文形态规则由中文排版替代；故意增加个性、强立场、反常节奏、个人经历、AI 分数、URL 清理、自动安装和多轮评分不采用。中文 ZH13/ZH14 的作者鉴定假设不采用；名词化和长定语作为可观察的表达问题处理。

这些是按作用归类的覆盖与取舍，不宣称逐条移植 55 条规则，也未导入检测器或上游 CLI。

## 上游验证：能支持什么

- technical-writing：所下载提交只有 SKILL、README、LICENSE 和 UI 元数据；有修复示例，未发现可运行评测或结果。不能把示例当独立验证。
- plain-writing：67 个任务；README 记录 skill/baseline/tie 为 65/2/0，规则级为 705/232/738，生成与评委均为 gpt-5.5。仓库提供数据和评测脚本，但 outputs 被忽略，缺少完整原始结果；评委解析/调用异常可记 tie。属于英文 LLM 评判快照，没有中文、GLM 或人工一致性验证。不能移用其胜率作为本 skill 效果。
- blader：有结构/包验证脚本和示例；本次未发现中文改写效果对照报告。包验证不证明文风收益。
- Aboudjem：8 个触发/行为案例说明手动执行，并明确没有自动触发评测框架。CLI README 描述 64 个确定性测试及启发式分数；这不是人工认可率或中文质量验证。本次未运行其代码。中文附录明确标为未经中文母语写手校验的实验稿。

本地验证独立记录在 tests/README.md 和 tests/validation-results.md。维护时获取新提交、检查上游差异、更新取舍与许可证、重跑本地案例；不要因为上游增加模式就自动扩大正文规则。
