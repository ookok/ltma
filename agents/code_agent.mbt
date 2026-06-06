///|
/// CodeAgent — programming agent with file I/O tools.

///|
pub fn create_code_agent_handle(
  provider : @llm.LLMProviderHandle,
  registry : @tool.ToolRegistry,
  workspace : String,
) -> @core.AgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  let sys_prompt = "You are an expert programming assistant. You can read, write, and edit files using the available tools. Provide clear, well-commented code. Current workspace: \{workspace}"
  messages.push(@llm.ChatMessage::new(@llm.ChatRole::system(), sys_prompt))

  let tool_defs : Array[@llm.ChatToolDef] = []
  let definitions = registry.list_defs()
  for i = 0; i < definitions.length(); i = i + 1 {
    let d = definitions[i]
    tool_defs.push(
      @llm.ChatToolDef::create(d.name, d.description, d.parameters, d.strict),
    )
  }

  @core.make_handle(
    (),
    fn(_) -> String { "code-agent" },
    fn(_) -> @core.AgentMetadata {
      @core.AgentMetadata::create(
        @core.AgentId::create("code", "0.1.0", "livingtree/ltma"),
        "AI coding assistant with file I/O capabilities",
        ["code", "programming", "file", "read", "write", "edit", "fs"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx : @core.AgentContext) -> Unit { messages = [] },
    fn(_, input : @core.Message) -> @core.Message {
      if input.is_text() {
        let user_text = input.get_text()
        messages.push(@llm.ChatMessage::new(@llm.ChatRole::user(), user_text))
        let resp = provider.chat(messages, Some(tool_defs))
        match resp.tool_calls {
          Some(calls) => {
            if resp.content != "" {
              messages.push(
                @llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content),
              )
            }
            for j = 0; j < calls.length(); j = j + 1 {
              let core_call = @core.ToolCall::create(
                calls[j].id,
                calls[j].name,
                calls[j].arguments,
              )
              let tool_result = registry.execute(
                core_call.name,
                core_call.arguments,
              )
              let result_str = match tool_result {
                Some(v) => v
                None => "tool not found: \{core_call.name}"
              }
              messages.push(
                @llm.ChatMessage::new(@llm.ChatRole::tool(), result_str),
              )
            }
            let follow_up = provider.chat(messages, Some(tool_defs))
            messages.push(
              @llm.ChatMessage::new(
                @llm.ChatRole::assistant(),
                follow_up.content,
              ),
            )
            @core.Message::text(follow_up.content)
          }
          None => {
            messages.push(
              @llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content),
            )
            @core.Message::text(resp.content)
          }
        }
      } else {
        @core.Message::text("unsupported message type")
      }
    },
    fn(_) -> Unit { messages = [] },
    fn(_) -> @core.AgentStatus { @core.AgentStatus::idle() },
    fn(_, call : @core.ToolCall) -> @core.ToolResult {
      let result = registry.execute(call.name, call.arguments)
      let success = result is Some(_)
      let output = result.unwrap_or("")
      @core.ToolResult::create(call.id, success, output, None)
    },
  )
}
