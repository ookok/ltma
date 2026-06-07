///|
/// AddInSideAdapter — MAF AddInSideAdapter equivalent.
///
/// In MAF, the AddInSideAdapter lives in the add-in's AppDomain and
/// translates between the contract and the add-in's view.
/// Here it wraps an AgentHandle or AgentBase into a ContractHandle
/// that the host side can communicate with.

///|
/// AddInSideAdapter — wraps an AgentHandle as a ContractHandle.
pub struct AddInSideAdapter {
  handle : @core.AgentHandle
  mut st : @core.AgentStatus
}

///|
pub fn AddInSideAdapter::new(handle : @core.AgentHandle) -> AddInSideAdapter {
  let st = handle.status()
  { handle, st }
}

///|
pub fn AddInSideAdapter::status(self : AddInSideAdapter) -> @core.AgentStatus {
  self.st
}

///|
pub fn AddInSideAdapter::initialize(
  self : AddInSideAdapter,
  ctx : @core.AgentContext,
) -> Unit {
  self.st = @core.AgentStatus::initializing()
  self.handle.init(ctx)
  self.st = @core.AgentStatus::idle()
}

///|
pub fn AddInSideAdapter::call(
  self : AddInSideAdapter,
  input : @core.Message,
) -> @core.Message {
  self.st = @core.AgentStatus::running()
  let result = self.handle.run(input)
  self.st = @core.AgentStatus::idle()
  result
}

///|
pub fn AddInSideAdapter::shutdown(self : AddInSideAdapter) -> Unit {
  self.handle.shutdown()
  self.st = @core.AgentStatus::shutdown_st()
}

///|
pub fn AddInSideAdapter::execute_tool(
  self : AddInSideAdapter,
  call : @core.ToolCall,
) -> @core.ToolResult {
  self.handle.execute_tool(call)
}

///|
pub fn AddInSideAdapter::metadata(
  self : AddInSideAdapter,
) -> @core.AgentMetadata {
  self.handle.metadata()
}

///|
pub fn AddInSideAdapter::agent_id(self : AddInSideAdapter) -> @core.AgentId {
  self.handle.metadata().id
}

///|
/// Convert an AddInSideAdapter into a ContractHandle for the pipeline.
pub fn AddInSideAdapter::to_contract(
  self : AddInSideAdapter,
) -> @core.ContractHandle {
  let self_ref = self
  @core.ContractHandle::create(
    fn(ctx) { self_ref.initialize(ctx) },
    fn(msg) { self_ref.call(msg) },
    fn() { self_ref.shutdown() },
    fn() { self_ref.status() },
    fn(call) { self_ref.execute_tool(call) },
  )
}
