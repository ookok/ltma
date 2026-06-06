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
      "You are a helpful AI assistant with access to tools.",
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
        "Async LLM-powered chat agent",
        ["chat", "tools", "async"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx) { messages = [] },
    async fn(_, input) -> @core.Message {
      if input.is_text() {
        messages.push(@llm.ChatMessage::new(@llm.ChatRole::user(), input.get_text()))
        let resp = provider.chat(messages, Some(tool_defs))
        messages.push(@llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content))
        @core.Message::text(resp.content)
      } else {
        @core.Message::text("unsupported message type")
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
