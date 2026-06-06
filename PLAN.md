# LTMA (LivingTreeMoonBitAgent) 框架计划

> 参考：Microsoft MAF (Managed Add-in Framework) 管线架构 + LTAI for .NET 六层架构设计
> 语言：MoonBit (beta-preview)
> 目标：构建云边一体的 AI Agent 框架，支持 WASM/JS/Native 三后端

---

## 1. 核心架构思想

### 1.1 MAF 管线范式在 MoonBit 中的适配

MAF 的 7 段管线（Host → HostView → HostAdapter → Contract → AddinAdapter → AddinView → Addin）在 MoonBit 中简化为 5 层：

```
┌─────────────┐
│   Host App  │  CLI / TUI / Web — 消费端
├─────────────┤
│  HostView   │  主机视图抽象（AgentHost API）
├─────────────┤
│  HostAdapter│  主机侧适配器（协议转换、生命周期管理）
├─────────────┤
│ ─ Contract ─│  ★ 契约层（不可变协议，纯数据 + 接口）
├─────────────┤
│ AgentAdapter│  Agent 侧适配器（工具调度、状态管理）
├─────────────┤
│  AgentView  │  Agent 基类抽象
├─────────────┤
│   Agent     │  具体 Agent 实现
└─────────────┘
```

**差异与取舍：**

| MAF 原语 | MoonBit 替代 | 说明 |
|----------|-------------|------|
| AppDomain 隔离 | WASM 沙箱 / 进程隔离 | MoonBit 无 AppDomain，用 WASM target 实现 Agent 隔离 |
| `IContract` + `ContractBase` | `trait` 接口 + 纯数据结构 | MoonBit trait 系统更简洁，无 remoting 开销 |
| `[AddInContract]` 等特性 | 按约定目录组织 + `moon.pkg` 标签 | MoonBit 无 Attribute，用命名约定 |
| `AddInToken.Activate<T>()` | `AgentHost::register + activate` | 工厂函数 + 包注册 |
| `ContractHandle` 引用计数 | 无跨域 GC 问题 | MoonBit 单进程内无 AppDomain，GC 统一管理 |
| 视图/适配器版本容错 | 语义化版本 + 契约兼容性测试 | 编译期类型检查已保证接口兼容 |

### 1.2 六层架构

```
L6 ┌─────────────────────────────────────────────────────┐
    │  Agent Layer — 智能体层                             │
    │  Agent 定义、组合、Workflow 编排                    │
L5 ─┼─────────────────────────────────────────────────────┤
    │  Orchestration — 编排路由层                         │
    │  Agent 注册发现、向量路由、任务调度                  │
L4 ─┼─────────────────────────────────────────────────────┤
    │  Tool System — 工具系统层                           │
    │  ToolRegistry、权限矩阵、工具执行沙箱               │
L3 ─┼─────────────────────────────────────────────────────┤
    │  Memory & Knowledge — 记忆知识层                    │
    │  Vector Store、Knowledge Graph、会话管理            │
L2 ─┼─────────────────────────────────────────────────────┤
    │  LLM & Safety — LLM 与安全层                        │
    │  多 Provider、安全护栏、降级链                      │
L1 ─┼─────────────────────────────────────────────────────┤
    │  Pipeline Runtime — 管线运行时                      │
    │  契约调度、生命周期管理、隔离沙箱                   │
L0 ─┼─────────────────────────────────────────────────────┤
    │  Core — 核心基础层                                  │
    │  基础类型、Contract 接口、错误类型、工具原语        │
    └─────────────────────────────────────────────────────┘
```

---

## 2. 包结构与目录设计

```
ltai4mb/
│
├── moon.mod                    # 模块标识: livingtree/ltma
│                               # version: 0.1.0, preferred-target: native
│
├── moon.work                   # 工作空间定义（支持多模块）
│
├── moon.pkg                    # 根包：重导出 + 便利 API
│
├── core/                       # ★ L0: 核心基础
│   ├── moon.pkg
│   ├── contract.mbt           # IAgentContract, IToolContract 等 trait 定义
│   ├── types.mbt              # AgentId, Message, ToolCall, ToolResult, Status
│   ├── errors.mbt             # LError, ContractError, PipelineError
│   └── pipeline.mbt           # PipelineStage, IsolationLevel, ActivationArgs
│
├── pipeline/                   # ★ L1: 管线运行时 (MAF 核心)
│   ├── moon.pkg
│   ├── host_adapter.mbt       # HostAdapter: 主机侧协议转换
│   ├── agent_adapter.mbt      # AgentAdapter: Agent 侧协议转换
│   ├── lifecycle.mbt          # 生命周期管理 (init → activate → run → shutdown)
│   └── sandbox.mbt            # WASM 沙箱隔离 + 进程隔离抽象
│
├── host/                       # ★ 主机框架 (对应 MAF HostView)
│   ├── moon.pkg
│   ├── agent_host.mbt         # AgentHost: 主机引擎，管理多 Agent
│   ├── catalog.mbt            # AgentCatalog: Agent 注册与发现
│   ├── activation.mbt         # Agent 激活策略 (单例/每次新建/池化)
│   └── events.mbt             # 主机事件总线
│
├── agent/                      # ★ 智能体框架 (对应 MAF AgentView)
│   ├── moon.pkg
│   ├── base.mbt               # AgentBase: Agent 基类
│   ├── context.mbt            # AgentContext: 运行时上下文
│   ├── registry.mbt           # AgentRegistry: Agent 元数据注册
│   └── lifecycle.mbt          # Agent 生命周期回调
│
├── protocol/                   # 通信协议
│   ├── moon.pkg
│   ├── message.mbt            # 消息路由、序列化
│   ├── a2a.mbt                # Agent-to-Agent 通信协议
│   └── codec.mbt              # JSON/二进制编解码
│
├── llm/                        # ★ L2: LLM 集成
│   ├── moon.pkg
│   ├── provider.mbt           # LLMProvider trait
│   ├── deepseek.mbt           # DeepSeek 实现 (参考 openseek)
│   ├── openai.mbt             # OpenAI 兼容实现
│   ├── client.mbt             # HTTP 传输层 (async)
│   ├── safety.mbt            # 输出安全护栏
│   └── fallback.mbt           # 降级链 + Circuit Breaker
│
├── tool/                       # ★ L4: 工具系统
│   ├── moon.pkg
│   ├── registry.mbt           # ToolRegistry: 工具注册中心
│   ├── definition.mbt         # ToolDefinition, ToolCall, ToolResult
│   ├── permission.mbt         # PermissionMatrix: 权限矩阵
│   ├── builtin/               # 内置工具
│   │   ├── moon.pkg
│   │   ├── shell.mbt          # shell 命令执行
│   │   ├── read.mbt           # 文件读取
│   │   ├── edit.mbt           # 文件编辑
│   │   ├── write.mbt          # 文件写入
│   │   └── fs.mbt             # 文件系统操作
│   └── sandbox/               # 工具沙箱
│       ├── moon.pkg
│       ├── wasm.mbt           # WASM 沙箱
│       └── policy.mbt         # 执行策略
│
├── memory/                     # ★ L3: 记忆与知识
│   ├── moon.pkg
│   ├── store.mbt              # MemoryStore trait
│   ├── vector.mbt             # 向量存储 (集成 ONNX? 或 API 级)
│   ├── graph.mbt              # 知识图谱 (SQLite FTS5)
│   ├── session.mbt            # 会话管理
│   └── compaction.mbt         # 上下文压缩
│
├── orchestration/              # ★ L5: 编排路由
│   ├── moon.pkg
│   ├── router.mbt             # 向量路由器 (Top-K Agent 选择)
│   ├── workflow.mbt           # Workflow 编排 (顺序/并行/Handoff)
│   ├── planner.mbt            # 任务规划器
│   └── reflector.mbt          # 反射自检循环
│
├── agents/                     # ★ L6: 预置智能体
│   ├── moon.pkg
│   ├── chat.mbt               # ChatAgent: 通用对话 Agent
│   ├── code.mbt               # CodeAgent: 编程 Agent
│   ├── research.mbt           # ResearchAgent: 研究 Agent
│   └── orchestrator.mbt       # OrchestratorAgent: 编排 Agent
│
├── security/                   # 横切: 安全
│   ├── moon.pkg
│   ├── permission.mbt         # 权限系统
│   ├── audit.mbt              # 审计日志
│   └── policy.mbt             # 安全策略
│
├── telemetry/                  # 横切: 可观测性
│   ├── moon.pkg
│   ├── tracer.mbt             # 链路追踪
│   ├── metrics.mbt            # 指标收集
│   └── logger.mbt             # 结构化日志 (参考 openseek/logger)
│
├── cmd/                        # CLI 入口 (native)
│   └── ltma/
│       ├── moon.pkg           # is-main: true
│       ├── main.mbt           # CLI 入口
│       └── args.mbt           # 参数解析
│
├── tui/                        # TUI 入口 (native/js)
│   ├── moon.pkg
│   ├── app.mbt                # TUI App (依赖 mizchi/tui)
│   └── views.mbt              # 终端 UI 组件
│
└── web/                        # Web 入口 (js)
    ├── moon.pkg               # supported-targets: js
    ├── server.mbt             # HTTP 服务器
    └── routes.mbt             # API 路由 + A2A 端点
```

---

## 3. 契约设计 (Contract Layer = MAF IContract 等价物)

### 3.1 核心 Trait

```moonbit
// === core/contract.mbt ===

/// Agent 契约：主机与 Agent 之间的不可变协议
pub trait IAgentContract {
  // Agent 元数据
  fn id(Self) -> String
  fn metadata(Self) -> AgentMetadata

  // 生命周期
  fn init(Self, ctx : AgentContext) -> Unit!
  fn run(Self, input : Message) -> Message!
  fn shutdown(Self) -> Unit!

  // 工具调用
  fn execute_tool(Self, call : ToolCall) -> ToolResult!
}

/// 工具契约：工具定义与执行
pub trait IToolContract {
  fn definition(Self) -> ToolDefinition
  fn execute(Self, input : JsonValue) -> ToolResult!
}

/// 存储契约：记忆/知识存储
pub trait IStorageContract {
  fn store(Self, key : String, value : JsonValue) -> Unit!
  fn retrieve(Self, key : String) -> JsonValue?
  fn search(Self, query : String, top_k : Int) -> Vec[SearchResult]
}
```

### 3.2 核心类型

```moonbit
// === core/types.mbt ===

pub struct AgentId {
  name : String
  version : String
  package : String  // mooncakes 包路径
}

pub struct AgentMetadata {
  id : AgentId
  description : String
  capabilities : Vec[String]
  isolation : IsolationLevel
  target : Target
}

pub enum IsolationLevel {
  InProcess    // 同进程（默认，无隔离）
  WasmSandbox  // WASM 沙箱隔离
  Process      // 进程级隔离（native only）
}

pub enum Message {
  Text(String)
  ToolCall(ToolCall)
  ToolResult(ToolResult)
  System(SystemMessage)
  Structured(JsonValue)
}

pub struct ToolCall {
  id : String
  name : String
  arguments : JsonValue
}

pub struct ToolResult {
  id : String
  success : Bool
  output : JsonValue
  error : String?
}
```

---

## 4. 管线流程 (MAF Pipeline 在 MoonBit 中的实现)

### 4.1 激活流程

```
Host 调用 AgentHost::activate(agent_id)
  │
  ├─ 1. AgentCatalog::resolve(agent_id)      → 查找 Agent 元数据
  ├─ 2. Pipeline::create(isolation_level)     → 创建隔离环境
  │      ├─ InProcess → 直接引用 Agent 包
  │      ├─ WasmSandbox → 加载 WASM 模块，创建沙箱
  │      └─ Process     → 派生子进程 (native only)
  ├─ 3. HostAdapter::wrap(contract_ref)       → 创建主机侧适配器
  ├─ 4. AgentAdapter::wrap(agent_impl)        → 创建 Agent 侧适配器
  ├─ 5. contract.init(ctx)                    → 初始化 Agent
  └─ 6. 返回 agent_host_view (类型为 IAgentContract 的实现)
```

### 4.2 调用流程

```
Host → host_adapter.call(method, args)
  │
  ├─ 1. 序列化参数为协议格式
  ├─ 2. 跨隔离域传输 (WASM memory / IPC)
  ├─ 3. agent_adapter 反序列化
  ├─ 4. 调用 agent_impl 对应方法
  ├─ 5. 序列化结果
  ├─ 6. 跨隔离域传回
  └─ 7. host_adapter 反序列化返回
```

### 4.3 生命周期状态机

```
              ┌─────────┐
              │  New    │
              └────┬────┘
                   │ register
              ┌────▼────┐
              │Discovered│
              └────┬────┘
                   │ activate
              ┌────▼────┐
              │ Initializing
              └────┬────┘
                   │ init() ok
              ┌────▼────┐
              │  Idle   │◄────────────┐
              └────┬────┘             │
                   │ run()            │
              ┌────▼────┐             │
              │ Running │── error ────┤
              └────┬────┘             │
                   │ complete         │
              ┌────▼────┐             │
              │Completed│── restart ──┘
              └────┬────┘
                   │ shutdown
              ┌────▼────┐
              │Shutdown │
              └─────────┘
```

---

## 5. LLM 多 Provider 架构 (参考 ltai4net MultiProviderChatClient)

```
                    ┌─────────────────────────┐
                    │    LLMProvider trait    │
                    │  chat(messages) → Response │
                    └──────────┬──────────────┘
                               │ 实现
           ┌───────────────────┼───────────────────┐
           ▼                   ▼                   ▼
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │ DeepSeek     │   │   OpenAI     │   │ Anthropic    │
    │ Provider     │   │   Provider   │   │ Provider     │
    └──────────────┘   └──────────────┘   └──────────────┘

                    ┌─────────────────────────────┐
                    │    MultiProviderClient      │
                    │  round_robin / fallback     │
                    │  circuit_breaker            │
                    │  timeout + retry            │
                    └─────────────────────────────┘
```

---

## 6. 安全与隔离

| 维度 | 策略 |
|------|------|
| **Agent 隔离** | WASM 沙箱 (wasmtime) / 进程隔离 / 同进程（按场景选） |
| **工具隔离** | PermissionMatrix: 14 域 × N Agent |
| **LLM 安全** | 输入护栏 + 输出护栏 + 内容审查 |
| **审计** | JSONL 结构化审计日志 (参考 openseek/logger) |
| **资源控制** | Token Budget、CPU/Memory 限制 |

---

## 7. 实施路线图

### Phase 0 — Foundation (1-2 周)
- [ ] 初始化项目：`moon.mod`, `moon.pkg`, 工作空间
- [ ] `core/` 包：Contract trait、核心类型、错误类型
- [ ] `pipeline/` 包：HostAdapter/AgentAdapter 骨架、生命周期管理
- [ ] `host/` 包：AgentHost、AgentCatalog 基础
- [ ] `agent/` 包：AgentBase、AgentContext
- [ ] `cmd/ltma` CLI 入口：解析参数、启动 host
- [ ] 测试：核心类型 + 契约测试

**里程碑：** 实现基础的 Agent 注册 + 激活 + 调用管线（InProcess 模式）

### Phase 1 — LLM + Tools (2-3 周)
- [ ] `llm/` 包：LLMProvider trait、JSON 序列化
- [ ] `llm/deepseek.mbt`：DeepSeek Provider（参考 openseek）
- [ ] `llm/openai.mbt`：OpenAI 兼容 Provider
- [ ] `llm/safety.mbt`：安全护栏
- [ ] `llm/fallback.mbt`：降级链
- [ ] `tool/` 包：ToolRegistry、ToolDefinition
- [ ] `tool/builtin/`：shell, read, edit, write
- [ ] `tool/permission.mbt`：权限矩阵
- [ ] 集成：LLM → ToolCall → ToolResult 闭环

**里程碑：** 可运行一个完整 Agent 对话（LLM 调用 + 工具执行）

### Phase 2 — Memory + Orchestration (2-3 周)
- [ ] `memory/` 包：MemoryStore trait
- [ ] 向量存储集成（ONNX / API）
- [ ] 知识图谱 (SQLite FTS5)
- [ ] 会话管理 + 上下文压缩
- [ ] `orchestration/` 包：Workflow 编排
- [ ] Agent 向量路由
- [ ] 多 Agent Handoff

**里程碑：** 多 Agent 编排、带记忆的上下文对话

### Phase 3 — Isolation + Protocol (2-3 周)
- [ ] WASM 沙箱集成（wasmtime）
- [ ] `protocol/a2a.mbt`：Agent-to-Agent 协议
- [ ] `protocol/codec.mbt`：跨隔离域序列化
- [ ] 进程隔离模式 (native)
- [ ] 安全策略 + 审计日志
- [ ] 沙箱工具执行

**里程碑：** 隔离的 Agent 运行环境，A2A 通信

### Phase 4 — UI + Ecosystem (3-4 周)
- [ ] `tui/`：基于 mizchi/tui 的终端界面
- [ ] `web/`：HTTP API + A2A 端点（JS target）
- [ ] `agents/`：ChatAgent, CodeAgent, ResearchAgent 等预置 Agent
- [ ] `telemetry/`：链路追踪 + 指标 + 结构化日志
- [ ] 文档 + 示例
- [ ] mooncakes.io 发布

**里程碑：** 完整可用的 AI Agent 框架，TUI/Web/CLI 三个前端

---

## 8. 关键设计决策

| 决策 | 选择 | 依据 |
|------|------|------|
| 契约语言 | MoonBit trait (非 JSON Schema) | 编译期类型安全，无运行时开销 |
| 序列化格式 | JSON (基于 MoonBit 内置 ToJson/FromJson) | 通用性 + MoonBit 原生支持 |
| Agent 定义格式 | MoonBit 代码 (非 .agent.md) | 编译期检查，与 openseek 一致 |
| 依赖管理 | mooncakes.io + workspace | 社区标准 |
| 前端默认 | CLI (native) | 开发效率，CLI 优先 |
| 测试策略 | inline test + cram test (参考 openseek) | 已验证的方案 |
| WASM 沙箱 | wasmtime (native target) | ltai4net 已验证，成熟度最高 |
| 向量存储 | 第一阶段用 API 级嵌入，后续集成 ONNX | 降低初期复杂度 |

---

## 9. 依赖清单 (mooncakes.io)

```
livingtree/ltma              # 本模块
moonbitlang/core               # 标准库 (自动依赖)
mizchi/tui                     # TUI (Phase 4, js/native)
mizchi/signals                 # 响应式信号 (Phase 4)
mizchi/crater                  # Flexbox/Grid 布局 (Phase 4)
bobzhang/jsonl                 # JSONL 日志 (Phase 0, 参考 openseek)
```

---

## 10. 参考项目

| 项目 | 参考内容 |
|------|---------|
| **ltai4net** | 六层架构、MAF 范式、权限矩阵、降级链、A2A |
| **openseek** | MoonBit Agent 实现模式、LLM 客户端、工具注册、cram 测试 |
| **tui.mbt** | MoonBit TUI 组件模式、虚拟 DOM |
| **MAF (.NET)** | 管线隔离、契约设计、适配器模式、版本容错 |
| **LivingTreeAlAgent** | Agent 器官架构、MemPO 记忆、工具系统、DNA 引擎 |
