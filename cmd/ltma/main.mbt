///|
/// LTMA CLI — full pipeline demo.

///|
fn main {
  println("LTMA — LivingTreeMoonBitAgent v0.1.0")
  println("")

  let host = @host.AgentHost::new()

  let echo_meta = @agent.create_metadata("echo", "Simple echo agent", ["echo"])
  host.register(echo_meta, echo_handle)

  let registry = @tool.ToolRegistry::new()
  @builtin.register_builtins(registry)
  println("Tools registered: \{registry.count()}")

  let provider = @llm.create_mock_provider("Hello from the AI assistant!")
  let chat_handle = @agents.create_chat_agent_handle(provider, registry)
  let chat_meta = @agent.create_metadata("chat", "LLM chat agent", [
    "chat", "tools",
  ])
  host.register(chat_meta, fn() { chat_handle })
  println("Agents registered: \{host.list_registered().length()}")

  println("\n--- EchoAgent Test ---")
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

  println("\n--- ChatAgent Test ---")
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

  println("\n--- Router Test ---")
  let router = @orchestration.AgentRouter::new()
  router.register("echo", ["echo", "mirror", "reflect"])
  router.register("chat", ["chat", "conversation", "llm", "help"])
  let chat_task = "I need to chat about something"
  let echo_task = "please echo this"
  println(
    "Route '\{chat_task}' -> \{router.route(chat_task).unwrap_or("none")}",
  )
  println(
    "Route '\{echo_task}' -> \{router.route(echo_task).unwrap_or("none")}",
  )

  println("\n--- Planner Test ---")
  let planner = @orchestration.Planner::new(router)
  let wf1 = planner.plan("write code and test results")
  println("Planned workflow: \{wf1.count()} steps")
  let wf2 = planner.plan("research topic then write report")
  println("Planned workflow: \{wf2.count()} steps")

  println("\n--- Memory Test ---")
  let session = @memory.SessionManager::new()
  let mem_handle = @agents.create_chat_agent_handle_with_memory(
    provider, registry, session, "demo-session",
  )
  let mem_meta = @agent.create_metadata("chat-memory", "Memory chat agent", [
    "chat", "memory",
  ])
  host.register(mem_meta, fn() { mem_handle })
  let mem_id = @core.AgentId::create("chat-memory", "0.1.0", "livingtree/ltma")
  match host.activate(mem_id) {
    Some(a) => {
      let r1 = a.call(@core.Message::text("First message"))
      if r1.is_text() {
        println("Turn 1: \{r1.get_text()}")
      }
      let r2 = a.call(@core.Message::text("Second message"))
      if r2.is_text() {
        println("Turn 2: \{r2.get_text()}")
      }
      a.shutdown()
    }
    None => println("Memory agent not found")
  }
  println(
    "Session history: \{session.get_history("demo-session").length()} messages",
  )

  println("\n--- Knowledge Graph Test ---")
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
  println(
    "KG entities for 'moonbit': \{kg.search_entities("moonbit").length()}",
  )
  println("KI docs for 'LTMA': \{ki.search("LTMA").length()}")

  println("\n--- Knowledge Agent Demo ---")
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
  let know_id = @core.AgentId::create("knowledge", "0.1.0", "livingtree/ltma")
  match host.activate(know_id) {
    Some(a) => {
      let resp = a.call(@core.Message::text("Tell me about MoonBit"))
      if resp.is_text() {
        println("Knowledge: \{resp.get_text()}")
      }
      a.shutdown()
    }
    None => println("Knowledge agent not found")
  }

  println("\n--- CodeAgent Demo ---")
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

  println("\n--- ResearchAgent Demo ---")
  let research_provider = @llm.create_mock_provider(
    "Based on sources [1] and [2]: LTMA is an AI Agent framework built with MoonBit. [1] describes the MAF-inspired architecture, while [2] confirms MoonBit is the implementation language.",
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
  let research_id = @core.AgentId::create(
    "research", "0.1.0", "livingtree/ltma",
  )
  match host.activate(research_id) {
    Some(a) => {
      let resp = a.call(
        @core.Message::text("What is LTMA and what language is it built with?"),
      )
      if resp.is_text() {
        println("Research: \{resp.get_text()}")
      }
      a.shutdown()
    }
    None => println("ResearchAgent not found")
  }

  println("\n--- OrchestratorAgent Demo ---")
  let orchestrator_handle = @agents.create_orchestrator_agent_handle(
    provider, registry, host, router,
  )
  let orchestrator_meta = @agent.create_metadata(
    "orchestrator",
    "Multi-agent orchestrator",
    ["orchestrator", "coordination", "routing"],
  )
  host.register(orchestrator_meta, fn() { orchestrator_handle })
  let orchestrator_id = @core.AgentId::create(
    "orchestrator", "0.1.0", "livingtree/ltma",
  )
  match host.activate(orchestrator_id) {
    Some(a) => {
      let resp = a.call(
        @core.Message::text("I need to chat about MTMA and echo a message"),
      )
      if resp.is_text() {
        println("Orchestrator: \{resp.get_text()}")
      }
      a.shutdown()
    }
    None => println("OrchestratorAgent not found")
  }

  println("\n--- A2A Protocol Test ---")
  let a2a = @protocol.A2ARouter::new()
  a2a.register("echo", @protocol.create_echo_handler())
  let ping = @protocol.A2AMessage::create(
    "msg-1",
    "test-client",
    "echo",
    @protocol.A2AMessageKind::request(),
    "hello from A2A",
    None,
    0L,
  )
  let encoded = @protocol.encode_message(ping)
  println("Encoded: \{encoded}")
  match @protocol.decode_message(encoded) {
    Some(decoded) =>
      println("Decoded: from=\{decoded.from_agent} to=\{decoded.to_agent}")
    None => println("Decode failed")
  }
  match a2a.send(ping) {
    Some(resp) => println("A2A response: \{resp.payload}")
    None => println("No response")
  }

  println("\n--- Handoff Test ---")
  let ctx = Map([("session", "demo-123")])
  let handoff_req = @protocol.HandoffRequest::new(
    "chat", "echo", "say hello", ctx,
  )
  match @protocol.perform_handoff(a2a, handoff_req) {
    Some(resp) =>
      if resp.accepted {
        println("Handoff OK: \{resp.result.unwrap_or("ok")}")
      } else {
        println("Handoff denied: \{resp.error.unwrap_or("unknown")}")
      }
    None => println("Handoff failed")
  }

  println("\nLTMA pipeline demonstration complete.")
}
