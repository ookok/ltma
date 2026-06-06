# LTMA — LivingTreeMoonBitAgent

> **MAF-inspired AI Agent framework for MoonBit**  
> 多 Provider LLM、工具系统、记忆、RAG、编排 — 全部在 MoonBit 中实现

[![CI](https://github.com/ookok/ltma/actions/workflows/ci.yml/badge.svg)](https://github.com/ookok/ltma/actions/workflows/ci.yml)
![MoonBit](https://img.shields.io/badge/MoonBit-v0.9.3-blue)
![License](https://img.shields.io/badge/License-Apache%202.0-green)

---

## 特性

- **15+ LLM Provider** — DeepSeek、智谱、Kimi、Qwen、MiniMax、硅基流动、阶跃星辰、OpenAI 等，模型可选
- **流式响应** — SSE 流式输出，逐 token 显示
- **工具调用闭环** — LLM → tool_calls → 执行 → 回传 → 综合
- **SQLite 持久化** — KV 存储、会话历史、知识图谱
- **ONNX 本地嵌入** — MiniLM-L6-v2 通过 C FFI 调用 ONNX Runtime
- **RAG 管线** — 向量检索 → 知识图谱 → 上下文注入 → LLM 回答
- **多 Agent 协作** — 辩论、投票、工作流编排
- **A2A 协议** — Agent 间通信与 Handoff
- **REST API** — 内嵌 HTTP 服务器，支持 Web UI
- **工具沙箱** — 调用配额、路径限制、黑白名单
- **安全护栏** — LLM 输入/输出过滤、审计日志、权限策略
- **可观测性** — 结构化日志、链路追踪、指标收集、OpenTelemetry
- **跨平台** — Native + JS 双 target，WebView 桌面客户端

## 快速开始

### 前置条件

- MoonBit CLI (`moon` v0.1.20260529+)
- MSVC (Windows) 或 GCC (Linux/macOS)
- 可选：ONNX Runtime（本地嵌入需要）

### 运行演示

```bash
# 克隆项目
git clone https://github.com/ookok/ltma.git
cd ltma

# 设置 MSVC 环境 (Windows)
$env:INCLUDE = "..."
$env:LIB = "..."

# 运行完整演示
moon run cmd/ltma

# 运行指定 Agent
moon run cmd/ltma -- run echo "hello"
moon run cmd/ltma -- list
```

### LLM 聊天

```bash
# 使用 DeepSeek（免费 API Key）
moon run cmd/ltma -- async deepseek sk-your-key-here

# 指定模型
moon run cmd/ltma -- async deepseek deepseek-reasoner sk-xxx

# 列出所有 Provider
moon run cmd/ltma -- providers

# 启动 REST API 服务器
moon run cmd/desktop
# 然后打开 http://localhost:9090
```

## 架构

```
Host App ──→ AgentHost ──→ HostAdapter ──→ [Contract] ──→ AgentAdapter ──→ Agent
    │              │             │                        │                │
    │         AgentCatalog  EventBus                 ToolRegistry      ToolSandbox
    │              │                                       │
    │         A2ARouter                             15+ Built-in Tools
    │
 CLI / TUI / REST API / Desktop WebView
```

### 包结构

| 包 | 说明 |
|------|------|
| `core/` | 基础类型：AgentId、Message、AgentHandle、ToolCall |
| `pipeline/` | HostAdapter、AgentAdapter、生命周期管理、沙箱 |
| `host/` | AgentHost、AgentCatalog、EventBus、A2A 集成 |
| `agent/` | AgentBase、AgentSession、注册表、生命周期钩子 |
| `agents/` | ChatAgent、CodeAgent、KnowledgeAgent、OrchestratorAgent 等 |
| `llm/` | 15+ Provider、流式、重试、限速、安全护栏 |
| `tool/` | ToolRegistry、ToolSandbox、PermissionMatrix |
| `memory/` | 向量存储、知识图谱、关键词索引、会话管理 |
| `storage/` | SQLite 持久化（KV、会话、知识图谱） |
| `orchestration/` | 工作流、路由、规划器、多 Agent 协调 |
| `protocol/` | A2A 消息、编解码、Handoff |
| `security/` | 权限管理、审计日志、安全策略 |
| `telemetry/` | 日志、追踪、指标、OpenTelemetry |
| `embedding/` | ONNX Runtime C FFI、远程 Embedding API |
| `prompt/` | Prompt 模板引擎、技能系统、预设 prompt |
| `web/` | REST API 服务器、Web UI（Markdown + 代码高亮） |
| `tui/` | 终端交互式聊天 |
| `cmd/ltma/` | CLI 入口 |
| `cmd/desktop/` | 桌面客户端（内嵌 REST API） |

## 内置工具

| 分类 | 工具 | 说明 |
|------|------|------|
| Shell | `shell` | 命令执行（C FFI `_popen`） |
| 文件 | `read` `write` `edit` `ls` `stat` | 文件读写编辑、目录列表 |
| 搜索 | `grep` `glob` | 文件内容搜索、通配符匹配 |
| 网络 | `websearch` `webfetch` | DuckDuckGo 搜索、HTTP 抓取 |
| 计算 | `math` `random` | 算术求值、随机数 |
| 编码 | `base64_encode` `base64_decode` `json_format` `uuid` `hash` | 编解码、UUID、哈希 |
| 记忆 | `mem_store` `mem_recall` | Agent 上下文 KV 存储 |
| 任务 | `todo_add` `todo_list` | 任务跟踪 |
| 交互 | `question` `skill` | 用户输入、知识加载 |
| Agent | `task` | 子任务委派 |
| 演示 | `echo` `greet` | 回显、问候 |

## 项目状态

| 维度 | 状态 |
|------|------|
| 包数量 | 19 |
| 源文件 | 90+ |
| 测试 | 75 (全部通过) |
| 编译 | 0 错误 |
| Native | ✅ |
| JS | ✅ (JS target) |
| CI | ✅ GitHub Actions |

---

> **未完待续 — 下一步开发计划**

### Phase 5 — 生产就绪 (当前)

- [x] Async LLM 管线（真正 HTTP 调用）
- [x] 15+ 国产 Provider 支持
- [x] SSE 流式响应
- [x] 工具调用闭环（tool_calls → 执行 → 综合）
- [x] SQLite 持久化（KV、会话、知识图谱）
- [x] ONNX C FFI 本地嵌入（MiniLM-L6-v2）
- [x] REST API 服务器 + Web UI
- [x] 桌面客户端（WebView）
- [x] 工具沙箱（配额、路径、黑白名单）
- [x] LLM 重试 + 限速
- [x] 多 Agent 协作（辩论、投票）
- [x] Prompt 工程系统
- [x] RAG 管线
- [x] CI/CD

### Phase 6 — 增强

- [ ] 流式 TUI (逐 token 显示)
- [ ] vcdb 向量库集成 (等上游兼容)
- [ ] 多轮记忆持久化接入所有 Agent
- [ ] A2A 自动路由集成
- [ ] LLM Embedding API (OpenAI 兼容)
- [ ] Token 用量跟踪与计费
- [ ] 插件系统（动态加载 Agent）
- [ ] 模型自动下载

### Phase 7 — 生态

- [ ] mooncakes.io 发布
- [ ] API 文档生成
- [ ] Benchmark 基准测试
- [ ] 示例项目 / 模板
- [ ] WebSocket 支持（实时推送）
- [ ] OpenTelemetry 导出
- [ ] WASM 沙箱隔离
- [ ] 联邦学习 / 分布式 Agent

---

## 许可证

Apache License 2.0
