///|
/// Test utilities — mock agent factories and test helpers.

///|
/// MockAgentConfig — configuration for creating a mock agent.
pub struct MockAgentConfig {
  name : String
  version : String
  description : String
  capabilities : Array[String]
  echo_prefix : String
}

///|
pub fn MockAgentConfig::new(name : String) -> MockAgentConfig {
  {
    name,
    version: "0.1.0",
    description: "mock agent for testing",
    capabilities: ["echo"],
    echo_prefix: "echo: ",
  }
}

///|
/// Create a mock AgentHandle for testing.
pub fn create_mock_handle(config : MockAgentConfig) -> AgentHandle {
  let meta = AgentMetadata::create(
    AgentId::create(config.name, config.version, "livingtree/ltma"),
    config.description,
    config.capabilities,
    IsolationLevel::in_process(),
    Target::native(),
    config.version,
  )
  make_handle(
    config,
    fn(c) { c.name },
    fn(_c) { meta },
    fn(_c, _ctx) {  },
    fn(c, input) {
      if input.is_text() {
        Message::text(c.echo_prefix + input.get_text())
      } else {
        Message::text("unhandled")
      }
    },
    fn(_c) {  },
    fn(_c) { AgentStatus::idle() },
    fn(_c, call) { ToolResult::create(call.id, false, "", None) },
  )
}

///|
/// Create a mock ContractHandle for testing.
pub fn create_mock_contract(prefix : String) -> ContractHandle {
  ContractHandle::create(
    fn(_ctx) {  },
    fn(input) {
      if input.is_text() {
        Message::text(prefix + input.get_text())
      } else {
        Message::text("unhandled")
      }
    },
    fn() {  },
    fn() { AgentStatus::idle() },
    fn(call) { ToolResult::create(call.id, false, "", None) },
  )
}

///|
/// Create a simple test message.
pub fn test_message(text : String) -> Message {
  Message::text(text)
}

///|
/// Check that a message has the expected text content.
pub fn check_message_eq(msg : Message, expected : String) -> Bool {
  msg.is_text() && msg.get_text() == expected
}
