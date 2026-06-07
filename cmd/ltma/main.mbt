///|
/// LTMA CLI — entry point with command dispatch.

///|
fn main {
  let args = Args::parse()
  match args.command {
    Command::Help => print_help()
    Command::Version => println("LTMA v0.1.0")
    Command::Demo => run_demo()
    Command::ListAgents => cmd_list()
    Command::ListProviders => cmd_list_providers()
    Command::Run(agent, msg) => cmd_run(agent, msg)
    Command::Chat(agent) => cmd_chat(agent)
    Command::AsyncChat(provider_str, model_str, api_key) =>
      cmd_async_chat(provider_str, model_str, api_key)
  }
}

///|
/// Run an async chat with session memory.
fn cmd_async_chat(
  provider_str : String,
  model_str : String,
  api_key : String,
) -> Unit {
  println(
    "Connecting to \{provider_str} (model: \{if model_str != "" { model_str } else { "default" }})...",
  )
  @async.run_async_main(async fn() {
    match @llm.create_provider(provider_str, model_str, api_key) {
      Some(provider) => {
        let registry = @tool.ToolRegistry::new()
        @builtin.register_builtins(registry)

        let session = Some(@storage.SessionStore::open("ltma_sessions.db")) catch {
          _ => None
        }
        let agent = match session {
          Some(s) =>
            @agents.create_async_chat_agent_with_memory(
              provider, registry, s, "default",
            )
          None => @agents.create_async_chat_agent(provider, registry)
        }

        let ctx = @core.AgentContext::new(
          @core.AgentId::create("async-chat", "0.1.0", "livingtree/ltma"),
        )
        agent.init(ctx)
        let resp = agent.run(@core.Message::text("Hello! What can you do?"))
        if resp.is_text() {
          println("\nAgent: \{resp.get_text()}")
        } else {
          println("\nAgent: <non-text response>")
        }
        agent.shutdown()
      }
      None =>
        println(
          "Unknown provider: '\{provider_str}'. Use 'ltma providers' to list supported providers.",
        )
    }
  })
}

///|
fn cmd_list() -> Unit {
  let host = setup_host()
  let agents = host.list_registered()
  println("Registered agents (\{agents.length()}):")
  for a in agents {
    let caps = a.capabilities
    let mut cap_str = ""
    for i = 0; i < caps.length(); i = i + 1 {
      if i > 0 {
        cap_str = cap_str + ", "
      }
      cap_str = cap_str + caps[i]
    }
    println("  \{a.id.to_string()} — \{a.description}")
    println("    capabilities: [\{cap_str}]")
  }
}

///|
fn cmd_run(agent_name : String, msg : String) -> Unit {
  let host = setup_host()
  let input = if msg == "" { "hello" } else { msg }
  let id = @core.AgentId::create(agent_name, "0.1.0", "livingtree/ltma")
  match host.activate(id) {
    Some(a) => {
      let resp = a.call(@core.Message::text(input))
      if resp.is_text() {
        println("\{agent_name}: \{resp.get_text()}")
      } else {
        println("\{agent_name}: <non-text response>")
      }
      a.shutdown()
    }
    None => println("Agent '\{agent_name}' not found")
  }
}

///|
fn cmd_chat(agent_name : String) -> Unit {
  let host = setup_host()
  println(
    "Starting TUI chat interface with agent '\{agent_name}' (ESC to quit)...",
  )
  @tui.start_chat_tui(host, agent_name~)
}

///|
fn setup_host() -> @host.AgentHost {
  let host = @host.AgentHost::new()
  let registry = @tool.ToolRegistry::new()
  @builtin.register_builtins(registry)
  let provider = @llm.create_mock_provider("Hello from the AI assistant!")

  // Initialize ONNX embedding model
  // Try non-quantized model first (int8 has shape issues with ONNX RT v1.21)
  let model_file = if @xfs.path_exists("models/minilm-l6-v2/model.onnx") {
    "models/minilm-l6-v2/model.onnx"
  } else {
    "models/minilm-l6-v2/model.int8.onnx"
  }
  let embed_provider = @embedding.create_onnx_provider(
    model_file, "models/minilm-l6-v2/vocab.txt",
  )
  let echo_meta = @agent.create_metadata("echo", "Simple echo agent", ["echo"])
  host.register(echo_meta, echo_handle)

  let chat_handle = @agents.create_chat_agent_handle(provider, registry)
  let chat_meta = @agent.create_metadata("chat", "LLM chat agent", [
    "chat", "tools",
  ])
  host.register(chat_meta, fn() { chat_handle })

  let session = @memory.SessionManager::new()
  let mem_handle = @agents.create_chat_agent_handle_with_memory(
    provider, registry, session, "demo-session",
  )
  let mem_meta = @agent.create_metadata("chat-memory", "Memory chat agent", [
    "chat", "memory",
  ])
  host.register(mem_meta, fn() { mem_handle })

  let kg = @memory.KnowledgeGraph::new()
  kg.add_entity(
    @memory.Entity::new(
      "ltma", "LTMA", "framework", "AI Agent framework for MoonBit",
    ),
  )
  kg.add_entity(
    @memory.Entity::new("moonbit", "MoonBit", "language", "AI-native language"),
  )
  kg.add_entity(
    @memory.Entity::new("deepseek", "DeepSeek", "model", "Large language model"),
  )
  kg.add_relation(@memory.Relation::new("ltma", "built_with", "moonbit"))
  kg.add_relation(@memory.Relation::new("ltma", "uses", "deepseek"))
  let ki = @memory.KeywordIndex::new()
  ki.add_document(
    @memory.Document::new(
      "d1", "LTMA Framework", "LTMA is a MAF-inspired AI Agent framework for MoonBit",
    ),
  )

  // VectorStore with ONNX embeddings
  let vs = @memory.VectorStore::new(384)
  match embed_provider {
    Some(ep) => {
      vs.add_text(
        "ltma",
        "LTMA is a MAF-inspired AI Agent framework for MoonBit",
        Map([]),
        ep,
      )
      vs.add_text(
        "moonbit",
        "MoonBit is an AI-native programming language",
        Map([]),
        ep,
      )
      vs.add_text(
        "deepseek",
        "DeepSeek provides large language models",
        Map([]),
        ep,
      )
      println("VectorStore: \{vs.count()} docs indexed via ONNX")
    }
    None => println("VectorStore: ONNX model not available, skipping")
  }

  let know_provider = @llm.create_mock_provider(
    "Found relevant knowledge in my knowledge base.",
  )
  let know_handle = @agents.create_knowledge_agent_handle(
    know_provider, registry, kg, ki,
  )
  let know_meta = @agent.create_metadata("knowledge", "Knowledge agent", [
    "knowledge", "facts",
  ])
  host.register(know_meta, fn() { know_handle })

  let code_provider = @llm.create_mock_provider(
    "Here's the code you requested.",
  )
  let code_handle = @agents.create_code_agent_handle(
    code_provider, registry, "/workspace/ltma",
  )
  let code_meta = @agent.create_metadata("code", "Coding assistant", [
    "code", "programming", "file",
  ])
  host.register(code_meta, fn() { code_handle })

  let research_provider = @llm.create_mock_provider(
    "Based on sources [1] and [2]: LTMA is an AI Agent framework built with MoonBit.",
  )
  let research_handle = @agents.create_research_agent_handle(
    research_provider, registry, kg, ki,
  )
  let research_meta = @agent.create_metadata(
    "research",
    "Multi-source research agent",
    ["research", "knowledge", "synthesis"],
  )
  host.register(research_meta, fn() { research_handle })

  let router = @orchestration.AgentRouter::new()
  router.register("echo", ["echo", "mirror", "reflect"])
  router.register("chat", ["chat", "conversation", "llm", "help"])
  let orchestrator_handle = @agents.create_orchestrator_agent_handle(
    provider, registry, host, router,
  )
  let orchestrator_meta = @agent.create_metadata(
    "orchestrator",
    "Multi-agent orchestrator",
    ["orchestrator", "coordination", "routing"],
  )
  host.register(orchestrator_meta, fn() { orchestrator_handle })

  host
}

///|
/// Full pipeline demo — exercises all agents, tools, and subsystems.
fn run_demo() -> Unit {
  let host = setup_host()
  println("")
  println("--- EchoAgent Test ---")
  let echo_id = @core.AgentId::create("echo", "0.1.0", "livingtree/ltma")
  match host.activate(echo_id) {
    Some(a) => {
      let r = a.call(@core.Message::text("Hello LTMA!"))
      if r.is_text() {
        println("Echo: \{r.get_text()}")
      }
      a.shutdown()
    }
    None => println("EchoAgent not found")
  }

  println("")
  println("--- ChatAgent Test ---")
  let chat_id = @core.AgentId::create("chat", "0.1.0", "livingtree/ltma")
  match host.activate(chat_id) {
    Some(a) => {
      let r = a.call(@core.Message::text("What tools do you have?"))
      if r.is_text() {
        println("Chat: \{r.get_text()}")
      }
      a.shutdown()
    }
    None => println("ChatAgent not found")
  }

  println("")
  println("--- Knowledge Agent Test ---")
  let know_id = @core.AgentId::create("knowledge", "0.1.0", "livingtree/ltma")
  match host.activate(know_id) {
    Some(a) => {
      let resp = a.call(@core.Message::text("Tell me about MoonBit"))
      if resp.is_text() {
        println("Knowledge: \{resp.get_text()}")
      }
      a.shutdown()
    }
    None => println("KnowledgeAgent not found")
  }

  println("")
  println("--- CodeAgent Test ---")
  let code_id = @core.AgentId::create("code", "0.1.0", "livingtree/ltma")
  match host.activate(code_id) {
    Some(a) => {
      let resp = a.call(
        @core.Message::text("Write a factorial function in MoonBit"),
      )
      if resp.is_text() {
        println("Code: \{resp.get_text()}")
      }
      a.shutdown()
    }
    None => println("CodeAgent not found")
  }

  println("")
  println("--- LTMA pipeline demonstration complete. ---")
}

///|
fn cmd_list_providers() -> Unit {
  println(@llm.list_providers())
}
