///|
/// Async host-side adapter wrapping an async agent handle.

///|
pub struct AsyncHostAdapter {
  agent_id : @core.AgentId
  handle : @core.AsyncAgentHandle
  meta : @core.AgentMetadata
  mut st : @core.AgentStatus
}

///|
pub fn AsyncHostAdapter::new(handle : @core.AsyncAgentHandle) -> AsyncHostAdapter {
  let meta = handle.metadata()
  { agent_id: meta.id, handle, meta, st: @core.AgentStatus::new_st() }
}

///|
pub async fn AsyncHostAdapter::initialize(
  self : AsyncHostAdapter,
  ctx : @core.AgentContext,
) -> Unit {
  self.st = @core.AgentStatus::initializing()
  self.handle.init(ctx)
  self.st = @core.AgentStatus::idle()
}

///|
pub async fn AsyncHostAdapter::call(
  self : AsyncHostAdapter,
  input : @core.Message,
) -> @core.Message {
  self.st = @core.AgentStatus::running()
  let result = self.handle.run(input)
  self.st = @core.AgentStatus::idle()
  result
}

///|
pub fn AsyncHostAdapter::shutdown(self : AsyncHostAdapter) -> Unit {
  self.handle.shutdown()
  self.st = @core.AgentStatus::shutdown_st()
}

///|
pub fn AsyncHostAdapter::agent_id(self : AsyncHostAdapter) -> @core.AgentId {
  self.agent_id
}
