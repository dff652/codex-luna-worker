# Codex Luna Worker

用 `$luna` 把边界清晰的编码执行任务委托给 `gpt-5.6-luna` 子代理，同时让主代理继续负责需求判断、架构决策、代码审查和最终验收。

这套配置来自一次 Codex 自定义子代理实践，已去除本机项目路径、业务信息和私有配置，可供其他 Codex 用户独立安装。

## 适用场景

适合委托给 Luna：

- 验收标准明确的小功能实现；
- 已定位根因的 bug 修复；
- 范围有限的小型重构；
- 明确指定文件或模块的机械性编码工作。

保留给主代理：

- 模糊需求和产品决策；
- 跨模块架构设计；
- 高风险或破坏性操作；
- 最终 diff 审查与验收。

## 组成

```text
codex-luna-worker/
├── README.md
├── install.sh
├── agents/
│   └── luna-worker.toml
└── skills/
    └── luna/
        ├── SKILL.md
        └── agents/
            └── openai.yaml
```

- `luna-worker.toml`：定义 Luna 子代理的模型、推理强度和执行边界。
- `SKILL.md`：定义主代理如何委托、等待、审查和验收。
- `openai.yaml`：把 skill 暴露为 `$luna`，并关闭隐式触发。
- `install.sh`：安装到用户级 Codex 目录；遇到不同内容的既有文件会停止，不会静默覆盖。

## 前置条件

- 使用支持自定义 subagent 和 skill 的当前 Codex CLI、IDE Extension 或桌面应用；
- 当前账号或工作区可以使用 `gpt-5.6-luna`；
- macOS/Linux 安装脚本需要 Bash 和标准 `install`、`cmp` 命令；Windows 用户可按下方路径手动复制。

本配置在 `codex-cli 0.145.0` 上验证。Codex 的自定义 agent 格式仍可能演进，升级后若加载失败，应先查阅当前官方文档。

## 安装

在本目录执行：

```bash
./install.sh
```

默认安装位置：

```text
Agent: ${CODEX_HOME:-$HOME/.codex}/agents/luna-worker.toml
Skill: $HOME/.agents/skills/luna/
```

如需自定义 skill 根目录，可在运行时设置 `CODEX_SKILLS_DIR`：

```bash
CODEX_SKILLS_DIR=/absolute/path/to/skills ./install.sh
```

也可以完全通过参数指定两个安装根目录：

```bash
./install.sh --codex-home /absolute/path/to/codex-home --skills-dir /absolute/path/to/skills
```

安装脚本不访问网络，不修改仓库源码，也不会覆盖内容不同的既有配置。若目标文件已存在，请先人工比较并决定保留哪一份。

安装后重启 Codex、重新加载 IDE Extension，或开启新会话。自定义 agent 和 skill 通常在会话启动时加载。

## 使用

在新会话中输入：

```text
$luna 修复登录页表单校验问题，并运行相关测试
```

更完整的任务描述效果更稳定：

```text
$luna 修复用户列表翻页后筛选条件丢失的问题。
只修改用户管理页面及其测试；不要调整 API 协议。
验收：切换页码后筛选条件仍保留，相关前端测试通过。
```

执行流程：

1. 主代理确认任务边界和验收条件；
2. 主代理启动一个 `luna-worker`；
3. Luna 检查代码、实现修改并运行最小相关验证；
4. 主代理等待完成并检查真实工作区 diff；
5. 主代理补充验证并向用户报告最终结果。

`$luna` 被配置为仅显式触发。普通编码请求不会自动启用它。

## High 与 Max

默认配置为：

```toml
model = "gpt-5.6-luna"
model_reasoning_effort = "max"
```

`Luna` 是模型，`high`/`max` 是推理强度，不是不同部署。本项目默认使用 `max`，让 Luna 在边界清晰的编码任务上投入更充分的推理与检查时间；相应地，延迟和 token 消耗通常也会增加。如果更看重响应速度和成本，可以把已安装 agent 文件改为：

```toml
model_reasoning_effort = "high"
```

即使使用 `max`，复杂、开放式任务仍更适合由 Sol 或主代理完成；Luna 继续只负责边界明确、可独立验证的执行任务。

## 为什么不是 `/luna`

Codex 当前推荐使用 skill，显式调用形式是 `$luna`。旧式自定义 Prompt 可以形成 `/prompts:luna`，但该机制已经弃用；当前没有公开支持的方式注册一个独立顶级 `/luna` 命令。

## 验证与排障

确认文件已安装：

```bash
test -f "${CODEX_HOME:-$HOME/.codex}/agents/luna-worker.toml" && test -f "${CODEX_SKILLS_DIR:-$HOME/.agents/skills}/luna/SKILL.md" && echo OK
```

检查 Codex 配置：

```bash
codex --strict-config doctor --summary
```

如果 `$luna` 没有出现：

1. 确认安装命令与启动 Codex 的用户相同；
2. 检查是否设置了非默认 `CODEX_HOME` 或 `CODEX_SKILLS_DIR`；
3. 重启 Codex或重新加载 IDE Extension；
4. 开启新会话后再输入 `$luna`；
5. 确认工作区策略允许 subagent，并确认账号可用 `gpt-5.6-luna`。

如果提示 `luna-worker` 不可用，优先检查 agent 文件位置、TOML 格式和模型权限。skill 会显式报错，不会悄悄换用另一个自定义 agent。

## 协作与安全边界

- 不要让多个可写子代理同时修改重叠文件；
- Luna 不应回滚或覆盖共享工作区中的既有改动；
- 主代理必须检查实际 diff，不能只相信子代理摘要；
- 生产部署、删除、发布等高风险操作不应作为无监督的 Luna 体力任务；
- 分享配置前不要加入 API key、MCP 凭据、内部路径或项目私有规则。

## 官方参考

- [Codex Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Build Skills](https://learn.chatgpt.com/docs/build-skills)
- [Codex Custom Prompts（已弃用）](https://learn.chatgpt.com/docs/custom-prompts)
