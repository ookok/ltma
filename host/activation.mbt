///|
/// Host-side activation for agents.

///|
pub enum ActivationStrategy {
  Singleton
  PerCall
}

///|
pub struct ActivationResult {
  adapter : @pipeline.HostAdapter
  strategy : ActivationStrategy
}

///|
pub fn ActivationResult::new(
  adapter : @pipeline.HostAdapter,
  strategy : ActivationStrategy,
) -> ActivationResult {
  { adapter, strategy }
}

///|
pub fn activate_in_process(
  factory : () -> @core.AgentHandle,
  agent_id : @core.AgentId,
) -> ActivationResult {
  let handle = factory()
  let adapter = @pipeline.HostAdapter::new(handle)
  let ctx = @core.AgentContext::new(agent_id)
  adapter.initialize(ctx)
  ActivationResult::new(adapter, ActivationStrategy::Singleton)
}

///|
pub fn deactivate(result : ActivationResult) -> Unit {
  result.adapter.shutdown()
}
