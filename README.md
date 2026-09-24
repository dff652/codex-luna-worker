<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="Codex Luna Worker delegates one bounded coding task to GPT-6 or GPT-5.6 Luna and returns the result to the primary agent for review">
</p>

<p align="center">
  用 <code>$luna</code> 或点名版本化 worker 委托清晰、可验证的编码任务；让主代理继续掌握范围、判断和最终验收。
</p>

<p align="center">
  <a href="#quick-start">快速开始</a> ·
  <a href="#how-it-works">工作方式</a> ·
  <a href="#configuration">配置</a> ·
  <a href="#troubleshooting">排障</a>
</p>

## Why Luna Worker

Codex Luna Worker 把“执行”从主会话中拆出来，同时保留可控边界：

- **明确选型**：`$luna` 默认使用 GPT-5.6；点名 `luna6-worker` 或 `luna56-worker` 可指定版本。
- **单一执行者**：一次只启动一个 Luna worker，避免多个写代理争抢同一批文件。
- **主代理验收**：Luna 完成实现和最小相关测试后，主代理检查真实 diff，再决定是否接受。
- **共享工作区友好**：子代理必须保留已有改动，遇到无法确认的文件所有权时停止并报告。

适合小功能、已定位的 bug、有限重构和明确文件范围的机械性修改。模糊需求、架构设计、破坏性操作与最终验收仍由主代理负责。

## Quick start

### 1. 安装或更新

在 Linux/macOS 上，首次安装和后续更新使用同一个入口，不需要先 clone 仓库：

```bash
curl -fsSLo luna-bootstrap.sh https://raw.githubusercontent.com/dff652/codex-luna-worker/main/bootstrap.sh
bash luna-bootstrap.sh
```

可先查看下载的脚本再运行。若已克隆仓库，也可以在仓库根目录运行 `./install.sh --update`。安装器会自动识别现有 `$HOME/.codex/skills/luna` 或 `$HOME/.agents/skills/luna`；新安装默认写入后者。若两个位置都装有 Luna，请用 `--skills-dir` 明确选择。Windows 用户可按项目结构手动复制对应文件。

`bootstrap.sh` 默认从 GitHub 下载 `v0.1.0` 标签对应的仓库归档，在临时目录执行其中的安装器，并清理临时目录。分开下载与执行便于先检查脚本内容，也能明确看到下载失败。

克隆方式同样支持：

```bash
git clone https://github.com/dff652/codex-luna-worker.git
cd codex-luna-worker
./install.sh --update
```

新安装默认写入以下位置；升级时 skill 会留在原安装目录：

```text
${CODEX_HOME:-$HOME/.codex}/agents/luna-worker.toml
${CODEX_HOME:-$HOME/.codex}/agents/luna6-worker.toml
${CODEX_HOME:-$HOME/.codex}/agents/luna56-worker.toml
$HOME/.agents/skills/luna/SKILL.md
$HOME/.agents/skills/luna/VERSION
```

`install.sh` 本身不访问网络。使用 `--update` 时，内容不同的旧文件会先备份到 `${CODEX_HOME:-$HOME/.codex}/backups/`，然后更新；相同内容保持不变。省略 `--update` 时，安装器仍拒绝覆盖内容不同的文件。安装后重启 Codex、重新加载 IDE Extension，或开启新会话。

### 2. 委托一个任务

```text
$luna 修复用户列表翻页后筛选条件丢失的问题。
只修改用户管理页面及其测试；不要调整 API 协议。
验收：切换页码后筛选条件仍保留，相关前端测试通过。
```

好的 `$luna` 请求通常包含三样东西：**任务边界、允许修改的范围、验收标准**。

也可以直接用自然语言指定模型：

```text
分配给 luna6-worker：修复用户列表翻页后筛选条件丢失的问题。
分配给 luna56-worker：修复用户列表翻页后筛选条件丢失的问题。
```

`luna6-worker` 固定使用 `gpt-6-luna`；`luna56-worker` 固定使用 `gpt-5.6-luna`。未指明版本的 `$luna` 或“分配给 luna-worker”仍使用 5.6。如果同时点名两个版本而未指定执行者，主代理会先询问选择，不会猜测或自动切换。

## How it works

```text
用户请求
   ↓
主代理：明确范围与验收条件
   ↓
选定的 Luna worker：检查代码 → 实现 → 最小相关验证
   ↓
主代理：检查真实 diff → 补充验证 → 最终交付
```

仓库中这些文件分别守住不同职责：

| 文件 | 作用 |
| --- | --- |
| `agents/luna6-worker.toml`、`agents/luna56-worker.toml` | 分别固定 GPT-6 和 GPT-5.6 模型、推理强度与编码执行边界 |
| `agents/luna-worker.toml` | 保留旧版 5.6 代理配置，供已有调用兼容使用 |
| `skills/luna/SKILL.md` | 根据用户指定的版本选择代理，并定义委托、等待、复核和汇报流程 |
| `skills/luna/agents/openai.yaml` | 暴露 `$luna`，让点名 worker 的自然语言请求也可触发 skill |
| `VERSION` | 声明版本，并复制到安装后的 skill 目录 |

## Configuration

两个版本默认都使用 Luna Max：

```toml
model = "gpt-5.6-luna"
model_reasoning_effort = "max"
```

`luna6-worker.toml` 的 `model` 为 `gpt-6-luna`。模型写在各自的代理文件里；调用时点名哪个 worker，就使用哪个固定模型。

`Luna` 是模型，`max` 是推理强度。Max 会给单个任务更多推理与检查时间，也通常带来更高延迟和 token 消耗。若更看重速度，可把已安装 agent 文件改为：

```toml
model_reasoning_effort = "high"
```

提高推理强度不会改变任务边界：开放式、跨模块或高风险工作仍应留给 Sol 或主代理。

### 自定义安装目录

```bash
./install.sh --codex-home /absolute/path/to/codex-home --skills-dir /absolute/path/to/skills
```

也可通过 `CODEX_SKILLS_DIR` 指定 skill 根目录。Windows 用户可按项目结构手动复制对应文件。

### 升级已有安装

重新运行上面的 curl 命令即可。安装器会复用已存在的 skill 目录，并为内容不同的文件生成备份。旧的 `luna-worker.toml` 保留，仍固定使用 5.6。若你对已安装文件做过个性化修改，更新后可在输出的备份目录查看旧版本并合并这些修改。

若使用本地克隆，则先 `git pull`，再运行 `./install.sh --update`。`--codex-home` 和 `--skills-dir` 可指定非默认安装位置；远程入口也会将这些参数传给安装器，例如 `bash luna-bootstrap.sh --skills-dir "$HOME/.codex/skills"`。

### 版本与回退

仓库根目录的 `VERSION` 是包版本；安装后同名文件写在实际使用的 `luna` skill 目录中。查看默认位置的安装版本：

```bash
cat "$HOME/.agents/skills/luna/VERSION"
```

若此前安装在 `$HOME/.codex/skills`，改为查看 `$HOME/.codex/skills/luna/VERSION`。旧安装在首次升级前没有该文件。

远程入口可指定 Git tag，重新执行较早版本即可回退；更新前的文件仍会备份：

```bash
bash luna-bootstrap.sh --version v0.1.0
```

每次发布需同步修改 `VERSION` 与 `bootstrap.sh` 的默认 tag，提交后创建同名 Git tag，再推送提交和 tag。远程入口会检查归档中的 `VERSION` 与请求的 tag 是否一致。通过 tag 安装可复现该版本；直接从本地开发分支运行 `install.sh` 时，版本文件只表示该分支声明的包版本。

## Safety boundaries

- 不同时运行多个会修改重叠文件的子代理。
- 不让 Luna 执行无监督的删除、发布或生产部署。
- 不依赖子代理摘要代替真实 diff 和测试结果。
- 不在分享配置中加入 API key、MCP 凭据、内部路径或项目私有规则。
- 默认安装器遇到内容不同的目标文件会拒绝覆盖；`--update` 会先备份再替换。

## Troubleshooting

<details>
<summary><strong><code>$luna</code> 没有出现</strong></summary>

1. 确认安装命令与启动 Codex 的用户相同。
2. 检查是否设置了非默认 `CODEX_HOME` 或 `CODEX_SKILLS_DIR`。
3. 重启 Codex 或重新加载 IDE Extension。
4. 开启新会话后再次输入 `$luna`。
5. 确认工作区允许 subagent，且账号可用所选模型（`gpt-5.6-luna` 或 `gpt-6-luna`）。

</details>

<details>
<summary><strong>提示 Luna worker 不可用</strong></summary>

检查 agent 文件位置和 TOML 格式：

```bash
test -f "${CODEX_HOME:-$HOME/.codex}/agents/luna6-worker.toml" && test -f "${CODEX_HOME:-$HOME/.codex}/agents/luna56-worker.toml" && codex --strict-config doctor --summary
```

skill 会显式报告所选角色不可用，不会悄悄换用另一个模型。已有安装的更新步骤见上文“升级已有安装”。

</details>

<details>
<summary><strong>为什么不是 <code>/luna</code></strong></summary>

Codex 当前推荐用 `$luna` 显式调用 skill。旧式自定义 Prompt 可以形成 `/prompts:luna`，但该机制已经弃用；当前没有公开支持的方式注册独立顶级 `/luna` 命令。

</details>

## Compatibility

- 已在 `codex-cli 0.156.0` 验证配置加载与临时目录安装流程；尚未进行真实模型调用。
- 需要当前账号或工作区能够使用所选模型（`gpt-5.6-luna` 或 `gpt-6-luna`）。
- Codex 的自定义 agent 格式仍可能演进；升级后若加载失败，请先检查当前官方文档。

## References

- [Codex Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Build Skills](https://learn.chatgpt.com/docs/build-skills)
- [Custom Prompts（已弃用）](https://learn.chatgpt.com/docs/custom-prompts)

## License

[MIT](./LICENSE) © 2026 dff652
