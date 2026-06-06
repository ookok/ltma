///|
/// OrchestratorAgent — multi-agent task decomposition and coordination.
fn route_and_execute(
  host : @host.AgentHost,
  router : @orchestration.AgentRouter,
  task : String,
) -> String {
  match router.route(task) {
    Some(name) => {
      let id = @core.AgentId::create(name, "0.1.0", "livingtree/ltma")
      match host.activate(id) {
        Some(adapter) => {
          let resp = adapter.call(@core.Message::text(task))
          adapter.shutdown()
          if resp.is_text() {
            "[Agent \{name}]: \{resp.get_text()}"
          } else {
            "[Agent \{name}]: <non-text response>"
          }
        }
        None => "[no agent available: \{name}]"
      }
    }
    None => "[no suitable agent found for task]"
  }
}

///|
pub fn create_orchestrator_agent_handle(
  provider : @llm.LLMProviderHandle,
  registry : @tool.ToolRegistry,
  host : @host.AgentHost,
  router : @orchestration.AgentRouter,
) -> @core.AgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  messages.push(
    @llm.ChatMessage::new(
      @llm.ChatRole::system(),
      "You are an orchestrator. Decompose complex requests into sub-tasks and coordinate specialized agents to solve them. Synthesize results into a coherent final answer.",
    ),
  )

  @core.make_handle(
    (),
    fn(_) -> String { "orchestrator-agent" },
    fn(_) -> @core.AgentMetadata {
      @core.AgentMetadata::create(
        @core.AgentId::create("orchestrator", "0.1.0", "livingtree/ltma"),
        "Multi-agent orchestrator for task decomposition and coordination",
        ["orchestrator", "coordination", "decomposition", "routing"],
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

        // Try routing to an agent via the router
        let routed = route_and_execute(host, router, user_text)
        let agent_result = routed

        // Let LLM synthesize
        let synthesis_prompt = "Sub-agent result: \{agent_result}|\n\nSynthesize this into a final answer for the user."
        messages.push(
          @llm.ChatMessage::new(@llm.ChatRole::user(), synthesis_prompt),
        )
        let resp = provider.chat(messages, None)
        messages.push(
          @llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content),
        )
        @core.Message::text(resp.content)
      } else {
        @core.Message::text("unsupported")
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
