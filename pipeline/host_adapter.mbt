///|
/// Host-side adapter wrapping an agent handle with state management.

///|
pub struct HostAdapter {
  agent_id : @core.AgentId
  handle : @core.AgentHandle
  meta : @core.AgentMetadata
  mut st : @core.AgentStatus
}

///|
pub fn HostAdapter::new(handle : @core.AgentHandle) -> HostAdapter {
  let meta = handle.metadata()
  HostAdapter::new_with_meta(handle, meta)
}

///|
pub fn HostAdapter::new_with_meta(
  handle : @core.AgentHandle,
  metadata : @core.AgentMetadata,
) -> HostAdapter {
  {
    agent_id: metadata.id,
    handle,
    meta: metadata,
    st: @core.AgentStatus::new_st(),
  }
}

///|
pub fn HostAdapter::initialize(
  self : HostAdapter,
  ctx : @core.AgentContext,
) -> Unit {
  self.st = @core.AgentStatus::initializing()
  self.handle.init(ctx)
  self.st = @core.AgentStatus::idle()
}

///|
pub fn HostAdapter::call(
  self : HostAdapter,
  input : @core.Message,
) -> @core.Message {
  self.st = @core.AgentStatus::running()
  let result = self.handle.run(input)
  self.st = @core.AgentStatus::idle()
  result
}

///|
pub fn HostAdapter::shutdown(self : HostAdapter) -> Unit {
  self.handle.shutdown()
  self.st = @core.AgentStatus::shutdown_st()
}

///|
pub fn HostAdapter::status(self : HostAdapter) -> @core.AgentStatus {
  self.st
}

///|
pub fn HostAdapter::agent_id(self : HostAdapter) -> @core.AgentId {
  self.agent_id
}

///|
pub fn HostAdapter::metadata(self : HostAdapter) -> @core.AgentMetadata {
  self.meta
}
