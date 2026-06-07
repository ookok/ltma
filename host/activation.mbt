///|
/// Host-side activation for agents. Token-based lifetime management (MAF ActivationToken pattern).

///|
pub enum ActivationStrategy {
  Singleton
  PerCall
}

///|
/// ActivationToken — MAF-style handle proving an agent is activated.
pub struct ActivationToken {
  agent_id : @core.AgentId
  adapter : @pipeline.HostSideAdapter
  strategy : ActivationStrategy
  hooks : @agent.LifecycleHooks
}

///|
pub fn ActivationToken::new(
  agent_id : @core.AgentId,
  adapter : @pipeline.HostSideAdapter,
  strategy : ActivationStrategy,
  hooks : @agent.LifecycleHooks,
) -> ActivationToken {
  { agent_id, adapter, strategy, hooks }
}

///|
pub fn ActivationToken::agent_id(self : ActivationToken) -> @core.AgentId {
  self.agent_id
}

///|
pub fn ActivationToken::call(
  self : ActivationToken,
  msg : @core.Message,
) -> @core.Message {
  self.hooks.fire(@agent.LifecycleEvent::before_run(), self.agent_id)
  let result = self.adapter.call(msg)
  self.hooks.fire(@agent.LifecycleEvent::after_run(), self.agent_id)
  result
}

///|
pub fn ActivationToken::send(
  self : ActivationToken,
  msg : @core.Message,
) -> @core.Message {
  self.call(msg)
}

///|
/// call_with_trace — pass trace context through the middleware chain.
pub fn ActivationToken::call_with_trace(
  self : ActivationToken,
  msg : @core.Message,
  trace_id : String,
  span_id : String,
) -> @core.Message {
  self.hooks.fire(@agent.LifecycleEvent::before_run(), self.agent_id)
  let result = self.adapter.call_with_trace(msg, trace_id, span_id)
  self.hooks.fire(@agent.LifecycleEvent::after_run(), self.agent_id)
  result
}

///|
/// send_with_trace — convenience alias.
pub fn ActivationToken::send_with_trace(
  self : ActivationToken,
  msg : @core.Message,
  trace_id : String,
  span_id : String,
) -> @core.Message {
  self.call_with_trace(msg, trace_id, span_id)
}

///|
pub fn ActivationToken::shutdown(self : ActivationToken) -> Unit {
  self.hooks.fire(@agent.LifecycleEvent::before_shutdown(), self.agent_id)
  self.adapter.shutdown()
  self.hooks.fire(@agent.LifecycleEvent::after_shutdown(), self.agent_id)
}

///|
pub fn ActivationToken::status(self : ActivationToken) -> @core.AgentStatus {
  self.adapter.status()
}

///|
pub fn ActivationToken::initialize(
  self : ActivationToken,
  ctx : @core.AgentContext,
) -> Unit {
  self.hooks.fire(@agent.LifecycleEvent::before_init(), self.agent_id)
  self.adapter.initialize(ctx)
  self.hooks.fire(@agent.LifecycleEvent::after_init(), self.agent_id)
}

///|
pub fn ActivationToken::metadata(self : ActivationToken) -> @core.AgentMetadata {
  self.adapter.metadata()
}

///|
pub fn activate_in_process(
  factory : () -> @core.AgentHandle,
  agent_id : @core.AgentId,
) -> ActivationToken {
  activate_in_process_with_hooks(
    factory,
    agent_id,
    @agent.LifecycleHooks::new(),
  )
}

///|
pub fn activate_in_process_with_hooks(
  factory : () -> @core.AgentHandle,
  agent_id : @core.AgentId,
  hooks : @agent.LifecycleHooks,
) -> ActivationToken {
  let handle = factory()
  let contract = handle.contract()
  let meta = handle.metadata()
  let adapter = @pipeline.HostSideAdapter::new(contract, meta)
  let ctx = @core.AgentContext::new(agent_id)
  let token = ActivationToken::new(
    agent_id,
    adapter,
    ActivationStrategy::Singleton,
    hooks,
  )
  token.initialize(ctx)
  token
}

///|
pub fn deactivate(token : ActivationToken) -> Unit {
  token.shutdown()
}
