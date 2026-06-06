///|
/// Agent-side adapter — wraps an AgentHandle for protocol conversion.
/// Mirrors HostAdapter on the agent side of the contract boundary.

///|
pub struct AgentAdapter {
  handle : @core.AgentHandle
  mut st : @core.AgentStatus
}

///|
pub fn AgentAdapter::new(handle : @core.AgentHandle) -> AgentAdapter {
  let st = handle.status()
  { handle, st }
}

///|
pub fn AgentAdapter::status(self : AgentAdapter) -> @core.AgentStatus {
  self.st
}

///|
pub fn AgentAdapter::initialize(
  self : AgentAdapter,
  ctx : @core.AgentContext,
) -> Unit {
  self.st = @core.AgentStatus::initializing()
  self.handle.init(ctx)
  self.st = @core.AgentStatus::idle()
}

///|
pub fn AgentAdapter::call(
  self : AgentAdapter,
  input : @core.Message,
) -> @core.Message {
  self.st = @core.AgentStatus::running()
  let result = self.handle.run(input)
  self.st = @core.AgentStatus::idle()
  result
}

///|
pub fn AgentAdapter::shutdown(self : AgentAdapter) -> Unit {
  self.handle.shutdown()
  self.st = @core.AgentStatus::shutdown_st()
}

///|
pub fn AgentAdapter::execute_tool(
  self : AgentAdapter,
  call : @core.ToolCall,
) -> @core.ToolResult {
  self.handle.execute_tool(call)
}

///|
pub fn AgentAdapter::metadata(self : AgentAdapter) -> @core.AgentMetadata {
  self.handle.metadata()
}

///|
pub fn AgentAdapter::agent_id(self : AgentAdapter) -> @core.AgentId {
  self.handle.metadata().id
}

///|
/// Serialize a message for transport across the contract boundary.
pub fn serialize_message(msg : @core.Message) -> String {
  if msg.is_text() {
    "{\"kind\":\"text\",\"value\":\"" + msg.get_text() + "\"}"
  } else {
    "{\"kind\":\"system\"}"
  }
}

///|
/// Deserialize a message from transport format.
pub fn deserialize_message(data : String) -> @core.Message? {
  if data.contains("\"kind\":\"text\"") {
    let prefix = "\"value\":\""
    match data.find(prefix) {
      Some(start) => {
        let after = data.sub(start=start + prefix.length())
        match after.find("\"") {
          Some(end) =>
            Some(@core.Message::text(after.sub(start=0, end~).to_owned()))
          None => None
        }
      }
      None => None
    }
  } else {
    None
  }
}
