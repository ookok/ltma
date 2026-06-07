///|
/// Activation isolation — actual sandbox/process activation of agents.
///
/// MAF supports three isolation levels:
///   1. In-process (same AppDomain)
///   2. Same-process, different AppDomain (Wasm sandbox)
///   3. Different process (OS process)

///|
/// IsolationHost — strategy to activate an agent in a specific isolation context.
pub enum IsolationHost {
  InProcess
  WasmSandbox
  ExternalProcess
}

///|
/// ActivationConfig — configuration for activating an agent with isolation.
pub struct ActivationConfig {
  host : IsolationHost
  sandbox_config : @pipeline.SandboxConfig
  time_limit_ms : Int
  memory_limit_mb : Int
}

///|
pub fn ActivationConfig::in_process() -> ActivationConfig {
  {
    host: IsolationHost::InProcess,
    sandbox_config: @pipeline.SandboxConfig::in_process(),
    time_limit_ms: 0,
    memory_limit_mb: 0,
  }
}

///|
pub fn ActivationConfig::wasm(
  memory_mb : Int,
  time_ms : Int,
) -> ActivationConfig {
  {
    host: IsolationHost::WasmSandbox,
    sandbox_config: @pipeline.SandboxConfig::wasm(memory_mb, time_ms),
    time_limit_ms: time_ms,
    memory_limit_mb: memory_mb,
  }
}

///|
pub fn ActivationConfig::process(
  memory_mb : Int,
  time_ms : Int,
) -> ActivationConfig {
  {
    host: IsolationHost::ExternalProcess,
    sandbox_config: @pipeline.SandboxConfig::process(memory_mb, time_ms),
    time_limit_ms: time_ms,
    memory_limit_mb: memory_mb,
  }
}

///|
/// Activate an agent handle with explicit isolation configuration.
pub fn activate_with_isolation(
  handle : @core.AgentHandle,
  agent_id : @core.AgentId,
  config : ActivationConfig,
) -> ActivationToken {
  let contract = handle.contract()
  let meta = handle.metadata()
  let sandbox = @pipeline.create_sandbox(@core.IsolationLevel::in_process())
  sandbox.start()
  let adapter = @pipeline.HostSideAdapter::new(contract, meta)
  let ctx = @core.AgentContext::new(agent_id)
  adapter.initialize(ctx)
  // TODO: when config.host is WasmSandbox or ExternalProcess,
  // spawn the agent in the appropriate sandbox instead of in-process.
  let _ = config
  ActivationToken::new(
    agent_id,
    adapter,
    ActivationStrategy::Singleton,
    @agent.LifecycleHooks::new(),
  )
}
