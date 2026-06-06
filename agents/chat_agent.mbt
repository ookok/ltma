///|
/// ChatAgent with memory — LLM + Tools + Session persistence.

///|
/// Create an AgentHandle with memory support.
pub fn create_chat_agent_handle_with_memory(
  provider : @llm.LLMProviderHandle,
  registry : @tool.ToolRegistry,
  session : @memory.SessionManager,
  session_id : String,
) -> @core.AgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  messages.push(
    @llm.ChatMessage::new(
      @llm.ChatRole::system(),
      "You are a helpful AI assistant.",
    ),
  )

  // Restore previous session
  let history = session.get_history(session_id)
  for i = 0; i < history.length(); i = i + 1 {
    let role = if i % 2 == 0 {
      @llm.ChatRole::user()
    } else {
      @llm.ChatRole::assistant()
    }
    messages.push(@llm.ChatMessage::new(role, history[i]))
  }

  @core.make_handle(
    (),
    fn(_) { "chat-memory" },
    fn(_) {
      @core.AgentMetadata::create(
        @core.AgentId::create("chat-memory", "0.1.0", "livingtree/ltma"),
        "Chat agent with memory",
        ["chat", "memory", "tools"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx) { messages = [] },
    fn(_, input) -> @core.Message {
      if input.is_text() {
        let user_text = input.get_text()
        messages.push(@llm.ChatMessage::new(@llm.ChatRole::user(), user_text))
        session.add_message(session_id, user_text)
        let resp = provider.chat(messages, None)
        messages.push(
          @llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content),
        )
        session.add_message(session_id, resp.content)
        @core.Message::text(resp.content)
      } else {
        @core.Message::text("unsupported")
      }
    },
    fn(_) { messages = [] },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, call) -> @core.ToolResult {
      let result = registry.execute(call.name, call.arguments)
      @core.ToolResult::create(
        call.id,
        result is Some(_),
        result.unwrap_or(""),
        None,
      )
    },
  )
}

///|
/// Original chat agent (without memory, for backwards compatibility)
pub fn create_chat_agent_handle(
  provider : @llm.LLMProviderHandle,
  registry : @tool.ToolRegistry,
) -> @core.AgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  messages.push(
    @llm.ChatMessage::new(
      @llm.ChatRole::system(),
      "You are a helpful AI assistant with access to tools.",
    ),
  )

  @core.make_handle(
    (),
    fn(_) { "chat-agent" },
    fn(_) {
      @core.AgentMetadata::create(
        @core.AgentId::create("chat", "0.1.0", "livingtree/ltma"),
        "LLM-powered chat agent",
        ["chat", "tools"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx) { messages = [] },
    fn(_, input) -> @core.Message {
      if input.is_text() {
        messages.push(
          @llm.ChatMessage::new(@llm.ChatRole::user(), input.get_text()),
        )
        let resp = provider.chat(messages, None)
        messages.push(
          @llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content),
        )
        @core.Message::text(resp.content)
      } else {
        @core.Message::text("unsupported message type")
      }
    },
    fn(_) { messages = [] },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, call) -> @core.ToolResult {
      let result = registry.execute(call.name, call.arguments)
      @core.ToolResult::create(
        call.id,
        result is Some(_),
        result.unwrap_or(""),
        None,
      )
    },
  )
}
