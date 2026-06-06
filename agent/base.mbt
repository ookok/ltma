///|
/// AgentBase — helper to create AgentMetadata and default agent instances.

///|
pub struct AgentBase {
  metadata : @core.AgentMetadata
  mut st : @core.AgentStatus
}

///|
pub fn AgentBase::new(metadata : @core.AgentMetadata) -> AgentBase {
  { metadata, st: @core.AgentStatus::new_st() }
}

///|
pub fn create_metadata(
  name : String,
  description : String,
  capabilities : Array[String],
) -> @core.AgentMetadata {
  let id = @core.AgentId::create(name, "0.1.0", "livingtree/ltma")
  @core.AgentMetadata::create(
    id,
    description,
    capabilities,
    @core.IsolationLevel::in_process(),
    @core.Target::native(),
    "0.1.0",
  )
}

///|
pub fn AgentBase::id(self : AgentBase) -> String {
  self.metadata.id.to_string()
}

///|
pub fn AgentBase::metadata(self : AgentBase) -> @core.AgentMetadata {
  self.metadata
}

///|
pub fn AgentBase::status(self : AgentBase) -> @core.AgentStatus {
  self.st
}

///|
pub fn AgentBase::initialize(
  self : AgentBase,
  _ctx : @core.AgentContext,
) -> Unit {
  self.st = @core.AgentStatus::idle()
}

///|
pub fn AgentBase::run(self : AgentBase, input : @core.Message) -> @core.Message {
  if input.is_text() {
    @core.Message::text("echo: \{input.get_text()}")
  } else if input.is_system_shutdown() {
    self.st = @core.AgentStatus::shutdown_st()
    @core.Message::system_status_response(@core.AgentStatus::shutdown_st())
  } else if input.is_system_status_request() {
    @core.Message::system_status_response(self.st)
  } else {
    @core.Message::text("unhandled")
  }
}

///|
pub fn AgentBase::shutdown(self : AgentBase) -> Unit {
  self.st = @core.AgentStatus::shutdown_st()
}

///|
pub fn AgentBase::execute_tool(
  _self : AgentBase,
  call : @core.ToolCall,
) -> @core.ToolResult {
  @core.ToolResult::create(call.id, false, "", Some("no tool: \{call.name}"))
}
