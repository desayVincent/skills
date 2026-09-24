---
name: skill-eval
description: "按需使用本地私有评测套件评测 acme-writing-embedded-c 的触发和版本对照，报告可复核证据。首版仅支持这一目标 Skill。"
disable-model-invocation: true
---

# Skill 效果评测

本 Skill 是个人评测入口，不是通用 runner。首版只复用本地私有套件的 Codex A/B 和触发 runner；领域 fixture、隐藏预期及断言由该套件持有，不回写被测 Skill。其他 Skill 暂不提供可执行评测入口。

目录边界：个人仓被 Git 忽略的 `.scratch/skill-eval/suites/acme-writing-embedded-c/` 保存唯一的领域 runner、fixture 和判据；`.scratch/skill-eval/` 保存原始结果及内部设计文档。公开可安装的 `skill-eval/` 只放执行方法。公开仓不随附私有套件；本机没有套件时报告 `unverified`，不下载或补造判据。

## 1. 确定比较对象与用例

先读本地私有套件的 `README.md` 和两个 runner 的参数。修改已有 Skill 时，选定包含上版 Skill 的 Git commit 或 tag 作为 `--baseline-ref`，runner 固定到完整 commit；同批比较 `baseline` 与工作树 `candidate`。无 Skill 组只作可选参照。记录目标仓 HEAD、基线 commit、两版哈希、suite ID、fixture、公共 Skill、Codex 模型／推理档位和执行权限。没有固定旧版时不能宣称「改善」。

首次评测选一个真实修改 fixture、一个正触发、一个近邻负例和一个独立的确定性断言。从评测侧 `trigger_cases.json` 选择用例，不把用例与预期的对应关系写进可安装的 Skill：runner 会把公共 Skill 集挂载给受测 Agent。现有 suite 是 development/regression 集，不能当成独立 held-out 证据；修改 Skill 时不同时放宽 expected 或断言来证明提升。

核对 runner 是否仅向 Agent 提供公开 task 与 fixture；隐藏 oracle 与断言留在评测侧。完成本步时，能指出每例可见输入、私有判据及两版来源。

## 2. 选 runner 并确认安全边界

定位本地私有套件的 `run_ab.py` 和 `run_trigger_eval.py`，使用 `--agent codex --target-repo <被测仓根目录>`；先确认目录确由 Git 忽略，再检查两个脚本的 `--help`、目标 Skill 快照、`bwrap`／`prlimit`、Codex CLI 与所选受信 fixture。首版不安装、不依赖其他评测框架，也不开发新 runner。结果用 `--results` 指向个人仓中被 Git 忽略的新目录。

该 runner 将 Codex `auth.json` **只读映射进受测 Agent 沙箱，仍可被 Agent 读取**；Agent 有连接模型所需的网络。这是受信内置用例可接受的已知边界，不是凭据硬隔离。只对已核实的仓内受信 fixture 执行，并审计相关工具轨迹；新引入的不受信 prompt 改用专用低权限评测凭据。候选脚本的验证由 runner 在另一个无网、无凭据的 verifier 沙箱执行。无法确认预期的私密性或必要的外部写入授权时停止并报告 `unverified`。

## 3. 同条件执行并判定

按 runner 的同批冻结机制运行。先将 `SKILL_EVAL_HOME` 设为个人 `skills` 仓根目录，`TARGET_REPO` 设为被测团队仓根目录，`BASELINE_REF` 设为要比较的旧版 commit/tag，`FIXTURE_ID` 与 `TRIGGER_CASES` 从私有 manifest 中选择（触发用例至少一正例、一近邻负例）；每次运行使用新的结果目录：

```bash
: "${SKILL_EVAL_HOME:?set to personal skills repo root}"
: "${TARGET_REPO:?set to ACME team repo root}"
: "${BASELINE_REF:?set to the previous target-skill commit or tag}"
: "${FIXTURE_ID:?choose from the private fixtures manifest}"
: "${TRIGGER_CASES:?set positive and near-neighbor case IDs from the evaluator manifest}"
EVAL_SUITE="$SKILL_EVAL_HOME/.scratch/skill-eval/suites/acme-writing-embedded-c"
test -f "$EVAL_SUITE/run_ab.py" && test -f "$EVAL_SUITE/run_trigger_eval.py" || {
  echo 'private eval suite unavailable: unverified' >&2
  exit 1
}
python3 "$EVAL_SUITE/run_ab.py" \
  --target-repo "$TARGET_REPO" --baseline-ref "$BASELINE_REF" \
  --agent codex --fixtures "$FIXTURE_ID" \
  --model gpt-5.6-luna --reasoning-effort medium \
  --repeats 1 --jobs 1 --timeout 600 \
  --results "$SKILL_EVAL_HOME/.scratch/skill-eval/ab-$(date -u +%Y%m%dT%H%M%SZ)"
python3 "$EVAL_SUITE/run_trigger_eval.py" \
  --target-repo "$TARGET_REPO" \
  --agent codex --cases "$TRIGGER_CASES" \
  --model gpt-5.6-luna --reasoning-effort medium \
  --repeats 1 --jobs 1 --timeout 600 \
  --results "$SKILL_EVAL_HOME/.scratch/skill-eval/trigger-$(date -u +%Y%m%dT%H%M%SZ)"
```

本案显式选择 Codex `gpt-5.6-luna`／`medium`，与该 runner 的 Codex 默认配置一致。`--baseline-ref` 默认选 `baseline,candidate` 两组；历史版标签 `v0.3.0` 等仍可通过 `--variants` 复测，不与本次旧版混称。核对 metadata 的 `snapshots.baseline`、逐例 JSON 与原始事件中的运行信息、退出码及 `turn.completed`；参数或 metadata 只能证明请求配置，不能单独证明服务端实际模型。如宿主未提供独立的实际模型标识，报告这一观测限制。两组同批冻结、每次运行新会话，不跨 suite ID、Agent 宿主或旧 ZCode 批次拼接。若加测 `none`，核对公共 Skill／缓存未重新引入目标 Skill；仅删工作区 `SKILL.md` 不能证明无 Skill。无效样本按 runner 文档成组处理，不只补成功的一组。

从结果与轨迹分别判断目标 Skill **被读取／加载**、**被选用**及**实际交接**。现有触发 runner 的 `actual` 只表示目标内容被读取，`route` 只是预期标签；负例仍需结合最终回复核查。缺少可观察的选用／交接证据时，该结论为 `unverified`。

优先用 suite 的隐藏 oracle、diff 与构建结果判断功能；不加通用 Judge。候选引入的错误命令、构建／测试失败是任务失败；认证或传输错误记录为执行设施无效，停止本轮，待服务恢复后成组重跑。其他 runner／环境故障也须有证据才可排除；归因不明时保留样本并标待确认。

## 4. 报告与停止条件

从 `metadata.json`、逐例结果、`runs.json`、相关轨迹与 `summary.md` 核对宿主／实际模型、两版与 fixture 哈希、suite ID、命令／退出码、产物／diff、隐藏断言、wall time、token 和失败类型。原始结果只留个人忽略目录；对外提供证据先脱敏，不传播 credential、用户 Home 或无关上下文。遥测不可得写不可得，不填零；设施故障不能记作 Skill 失败。

单次只报告逐例观察，不报告触发率、稳定提升、置信区间或 pass@k；多次同条件执行后才附原始样本与适用的统计。不合并不同宿主或夹具的分数，不造统一 Skill Score 或合入门槛。静态检查、无独立 expected、基线污染、安全边界不可信或缺关键轨迹时，写 `unverified` 和具体缺口，不写 PASS。

完成依据是一份可追到版本、单例结果和未验证项的 Eval Report；host harness 结果不是板端验证。个人结果留在个人仓忽略目录；远程发布须另有授权。
