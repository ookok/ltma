///|
/// EchoAgent — demo agent using AgentHandle closures.

///|
pub fn echo_handle() -> @core.AgentHandle {
  let meta = @agent.create_metadata("echo", "Simple echo agent for testing", [
    "echo", "test",
  ])
  let base = @agent.AgentBase::new(meta)

  @core.make_handle(
    base,
    fn(a) { a.id() },
    fn(a) { a.metadata() },
    fn(a, ctx) { a.initialize(ctx) },
    fn(a, input) -> @core.Message {
      if input.is_text() {
        @core.Message::text("[EchoAgent] You said: \{input.get_text()}")
      } else if input.is_system_shutdown() {
        a.shutdown()
        @core.Message::system_status_response(@core.AgentStatus::shutdown_st())
      } else if input.is_system_status_request() {
        @core.Message::system_status_response(a.status())
      } else {
        @core.Message::text("unhandled")
      }
    },
    fn(a) { a.shutdown() },
    fn(a) { a.status() },
    fn(a, call) { a.execute_tool(call) },
  )
}
