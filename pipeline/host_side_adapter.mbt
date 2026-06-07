///|
/// HostSideAdapter — MAF HostSideAdapter equivalent.
///
/// In MAF, the HostSideAdapter lives in the host's AppDomain and
/// translates between the host's view of the add-in and the contract.
/// Here it wraps ContractHandle and adds host-side state management.

///|
pub struct HostSideAdapter {
  agent_id : @core.AgentId
  contract : @core.ContractHandle
  meta : @core.AgentMetadata
  mut st : @core.AgentStatus
  mut middleware : MiddlewarePipeline?
}

///|
pub fn HostSideAdapter::new(
  contract : @core.ContractHandle,
  meta : @core.AgentMetadata,
) -> HostSideAdapter {
  {
    agent_id: meta.id,
    contract,
    meta,
    st: @core.AgentStatus::new_st(),
    middleware: None,
  }
}

///|
pub fn HostSideAdapter::initialize(
  self : HostSideAdapter,
  ctx : @core.AgentContext,
) -> Unit {
  self.st = @core.AgentStatus::initializing()
  self.contract.init(ctx)
  self.st = @core.AgentStatus::idle()
}

///|

///|
pub fn HostSideAdapter::use_middleware(
  self : HostSideAdapter,
  pipeline : MiddlewarePipeline,
) -> Unit {
  self.middleware = Some(pipeline)
}

///|
pub fn HostSideAdapter::call(
  self : HostSideAdapter,
  input : @core.Message,
) -> @core.Message {
  self.st = @core.AgentStatus::running()
  let result = match self.middleware {
    Some(mw) => {
      let ctx = CallContext::new(self.agent_id.to_string(), input)
      let mut captured = @core.Message::text("")
      mw.execute(ctx, fn() {
        captured = self.contract.run(ctx.input)
        ctx.output = captured
      })
      captured
    }
    None => self.contract.run(input)
  }
  self.st = @core.AgentStatus::idle()
  result
}

///|
/// call_with_trace — call with trace context stored in middleware metadata.
pub fn HostSideAdapter::call_with_trace(
  self : HostSideAdapter,
  input : @core.Message,
  trace_id : String,
  span_id : String,
) -> @core.Message {
  self.st = @core.AgentStatus::running()
  let result = match self.middleware {
    Some(mw) => {
      let ctx = CallContext::new(self.agent_id.to_string(), input)
      ctx.set_meta("trace_id", trace_id)
      ctx.set_meta("span_id", span_id)
      let mut captured = @core.Message::text("")
      mw.execute(ctx, fn() {
        captured = self.contract.run(ctx.input)
        ctx.output = captured
      })
      captured
    }
    None => self.contract.run(input)
  }
  self.st = @core.AgentStatus::idle()
  result
}

///|
pub fn HostSideAdapter::shutdown(self : HostSideAdapter) -> Unit {
  self.contract.shutdown()
  self.st = @core.AgentStatus::shutdown_st()
}

///|
pub fn HostSideAdapter::status(self : HostSideAdapter) -> @core.AgentStatus {
  self.st
}

///|
pub fn HostSideAdapter::agent_id(self : HostSideAdapter) -> @core.AgentId {
  self.agent_id
}

///|
pub fn HostSideAdapter::metadata(self : HostSideAdapter) -> @core.AgentMetadata {
  self.meta
}
