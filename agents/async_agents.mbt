///|
/// Async-aware agent factory functions (for real HTTP API calls).

///|
pub fn create_async_chat_agent(
  provider : @llm.AsyncLLMProviderHandle,
  registry : @tool.ToolRegistry,
) -> @core.AsyncAgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  messages.push(
    @llm.ChatMessage::new(
      @llm.ChatRole::system(),
      "You are a helpful AI assistant with access to tools. " +
      "When you need to use a tool, respond with the appropriate tool call.",
    ),
  )

  let tool_defs : Array[@llm.ChatToolDef] = []
  let defs = registry.list_defs()
  for i = 0; i < defs.length(); i = i + 1 {
    let d = defs[i]
    tool_defs.push(@llm.ChatToolDef::create(d.name, d.description, d.parameters, d.strict))
  }

  @core.make_async_handle(
    (),
    fn(_) { "async-chat" },
    fn(_) {
      @core.AgentMetadata::create(
        @core.AgentId::create("async-chat", "0.1.0", "livingtree/ltma"),
        "Async LLM-powered chat agent with tool execution",
        ["chat", "tools", "async"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx) { messages = [] },
    async fn(_, input) -> @core.Message {
      if !input.is_text() {
        return @core.Message::text("unsupported message type")
      }
      messages.push(@llm.ChatMessage::new(@llm.ChatRole::user(), input.get_text()))

      // LLM call with tool definitions
      let resp = provider.chat(messages, Some(tool_defs))

      match resp.tool_calls {
        Some(calls) => {
          // LLM wants to use tools
          if resp.content != "" {
            messages.push(
              @llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content),
            )
          }
          // Execute each tool call
          for j = 0; j < calls.length(); j = j + 1 {
            let core_call = @core.ToolCall::create(
              calls[j].id, calls[j].name, calls[j].arguments,
            )
            let result_str = match registry.execute(core_call.name, core_call.arguments) {
              Some(v) => v
              None => "error: tool '\{core_call.name}' not found"
            }
            messages.push(
              @llm.ChatMessage::new(@llm.ChatRole::tool(), result_str),
            )
          }
          // Follow-up: let LLM synthesize tool results
          let follow_up = provider.chat(messages, Some(tool_defs))
          messages.push(
            @llm.ChatMessage::new(@llm.ChatRole::assistant(), follow_up.content),
          )
          @core.Message::text(follow_up.content)
        }
        None => {
          // No tool calls — direct text response
          messages.push(
            @llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content),
          )
          @core.Message::text(resp.content)
        }
      }
    },
    fn(_) { messages = [] },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, call) -> @core.ToolResult {
      let result = registry.execute(call.name, call.arguments)
      let success = result is Some(_)
      let output = result.unwrap_or("")
      @core.ToolResult::create(call.id, success, output, None)
    },
  )
}

///|
/// Create an async chat agent with persistent session memory.
pub fn create_async_chat_agent_with_memory(
  provider : @llm.AsyncLLMProviderHandle,
  registry : @tool.ToolRegistry,
  session : @storage.SessionStore,
  session_id : String,
) -> @core.AsyncAgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  messages.push(
    @llm.ChatMessage::new(
      @llm.ChatRole::system(),
      "You are a helpful AI assistant with access to tools.",
    ),
  )

  // Restore session history
  let history = try { session.get_history(session_id) } catch { _ => [] }
  for i = 0; i < history.length(); i = i + 1 {
    let role = if i % 2 == 0 { @llm.ChatRole::user() } else { @llm.ChatRole::assistant() }
    messages.push(@llm.ChatMessage::new(role, history[i]))
  }

  let tool_defs : Array[@llm.ChatToolDef] = []
  let defs = registry.list_defs()
  for i = 0; i < defs.length(); i = i + 1 {
    let d = defs[i]
    tool_defs.push(@llm.ChatToolDef::create(d.name, d.description, d.parameters, d.strict))
  }

  @core.make_async_handle(
    (),
    fn(_) { "async-chat-memory" },
    fn(_) {
      @core.AgentMetadata::create(
        @core.AgentId::create("async-chat-memory", "0.1.0", "livingtree/ltma"),
        "Async chat agent with SQLite session memory",
        ["chat", "tools", "async", "memory"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx) { messages = [] },
    async fn(_, input) -> @core.Message {
      if !input.is_text() { return @core.Message::text("unsupported") }
      let user_text = input.get_text()
      messages.push(@llm.ChatMessage::new(@llm.ChatRole::user(), user_text))
      try { session.add_message(session_id, "user", user_text) } catch { _ => () }

      let resp = provider.chat(messages, Some(tool_defs))
      match resp.tool_calls {
        Some(calls) => {
          if resp.content != "" {
            messages.push(@llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content))
          }
          for j = 0; j < calls.length(); j = j + 1 {
            let core_call = @core.ToolCall::create(calls[j].id, calls[j].name, calls[j].arguments)
            let result_str = match registry.execute(core_call.name, core_call.arguments) {
              Some(v) => v
              None => "error: tool '\{core_call.name}' not found"
            }
            messages.push(@llm.ChatMessage::new(@llm.ChatRole::tool(), result_str))
          }
          let follow_up = provider.chat(messages, Some(tool_defs))
          messages.push(@llm.ChatMessage::new(@llm.ChatRole::assistant(), follow_up.content))
          try { session.add_message(session_id, "assistant", follow_up.content) } catch { _ => () }
          @core.Message::text(follow_up.content)
        }
        None => {
          messages.push(@llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content))
          try { session.add_message(session_id, "assistant", resp.content) } catch { _ => () }
          @core.Message::text(resp.content)
        }
      }
    },
    fn(_) { messages = [] },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, call) -> @core.ToolResult {
      let result = registry.execute(call.name, call.arguments)
      let success = result is Some(_)
      let output = result.unwrap_or("")
      @core.ToolResult::create(call.id, success, output, None)
    },
  )
}

///|
/// Create an async code agent with tool-call loop and workspace support.
pub fn create_async_code_agent(
  provider : @llm.AsyncLLMProviderHandle,
  registry : @tool.ToolRegistry,
  workspace : String,
) -> @core.AsyncAgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  let sys_prompt = "You are an expert programming assistant. You can read, write, and edit files using the available tools. Provide clear code. Current workspace: \{workspace}"
  messages.push(@llm.ChatMessage::new(@llm.ChatRole::system(), sys_prompt))

  let tool_defs : Array[@llm.ChatToolDef] = []
  let defs = registry.list_defs()
  for i = 0; i < defs.length(); i = i + 1 {
    let d = defs[i]
    tool_defs.push(@llm.ChatToolDef::create(d.name, d.description, d.parameters, d.strict))
  }

  @core.make_async_handle(
    (),
    fn(_) { "async-code" },
    fn(_) {
      @core.AgentMetadata::create(
        @core.AgentId::create("async-code", "0.1.0", "livingtree/ltma"),
        "Async code agent with file I/O tools",
        ["code", "programming", "file", "tools", "async"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx) { messages = [] },
    async fn(_, input) -> @core.Message {
      if !input.is_text() {
        return @core.Message::text("unsupported message type")
      }
      messages.push(@llm.ChatMessage::new(@llm.ChatRole::user(), input.get_text()))

      let resp = provider.chat(messages, Some(tool_defs))
      match resp.tool_calls {
        Some(calls) => {
          if resp.content != "" {
            messages.push(@llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content))
          }
          for j = 0; j < calls.length(); j = j + 1 {
            let core_call = @core.ToolCall::create(
              calls[j].id, calls[j].name, calls[j].arguments,
            )
            let result_str = match registry.execute(core_call.name, core_call.arguments) {
              Some(v) => v
              None => "error: tool '\{core_call.name}' not found"
            }
            messages.push(@llm.ChatMessage::new(@llm.ChatRole::tool(), result_str))
          }
          let follow_up = provider.chat(messages, Some(tool_defs))
          messages.push(@llm.ChatMessage::new(@llm.ChatRole::assistant(), follow_up.content))
          @core.Message::text(follow_up.content)
        }
        None => {
          messages.push(@llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content))
          @core.Message::text(resp.content)
        }
      }
    },
    fn(_) { messages = [] },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, call) -> @core.ToolResult {
      let result = registry.execute(call.name, call.arguments)
      let success = result is Some(_)
      let output = result.unwrap_or("")
      @core.ToolResult::create(call.id, success, output, None)
    },
  )
}

///|
/// RAG agent — Retrieval-Augmented Generation with vector store + knowledge graph.
pub fn create_rag_agent(
  provider : @llm.AsyncLLMProviderHandle,
  vector_store : @memory.VectorStore,
  embed_provider : @memory.EmbeddingProviderHandle,
  kg : @memory.KnowledgeGraph,
) -> @core.AsyncAgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  @core.make_async_handle(
    (),
    fn(_) { "rag-agent" },
    fn(_) {
      @core.AgentMetadata::create(
        @core.AgentId::create("rag-agent", "0.1.0", "livingtree/ltma"),
        "RAG knowledge agent with vector search + knowledge graph",
        ["rag", "knowledge", "vector", "search", "async"],
        @core.IsolationLevel::in_process(), @core.Target::native(), "0.1.0",
      )
    },
    fn(_, _ctx) { messages = [] },
    async fn(_, input) -> @core.Message {
      if !input.is_text() { return @core.Message::text("unsupported") }
      let query = input.get_text()
      let results = vector_store.search(query, 3, embed_provider)
      let mut context = ""
      for i = 0; i < results.length(); i = i + 1 {
        context = context + "[Doc] " + results[i].text + " (score:" + results[i].score.to_string() + ")\n"
      }
      let entities = kg.search_entities(query)
      for e in entities {
        context = context + "[KG] " + e.name + ": " + e.metadata + "\n"
      }
      let augmented = if context != "" { "Context:\n" + context + "\nQuestion: " + query } else { query }
      messages.push(@llm.ChatMessage::new(@llm.ChatRole::system(), "Answer based on retrieved context."))
      messages.push(@llm.ChatMessage::new(@llm.ChatRole::user(), augmented))
      let resp = provider.chat(messages, None)
      @core.Message::text(resp.content)
    },
    fn(_) { messages = [] },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, _call) -> @core.ToolResult { @core.ToolResult::create("", false, "", None) },
  )
}
