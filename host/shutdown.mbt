///|
/// Graceful shutdown — drain active calls, deactivate agents, clean up.

///|
/// ShutdownPhase — current phase of the shutdown process.
pub enum ShutdownPhase {
  Running
  Draining
  ShuttingDown
  Complete
}

///|
/// ShutdownConfig — how the shutdown should behave.
pub struct ShutdownConfig {
  drain_timeout_ms : Int
  force_kill_timeout_ms : Int
}

///|
pub fn ShutdownConfig::default() -> ShutdownConfig {
  { drain_timeout_ms: 5000, force_kill_timeout_ms: 10000 }
}

///|
/// GracefulShutdown — orchestrates the shutdown of an AgentHost.
pub struct GracefulShutdown {
  host : AgentHost
  config : ShutdownConfig
  mut phase : ShutdownPhase
}

///|
pub fn GracefulShutdown::new(host : AgentHost) -> GracefulShutdown {
  { host, config: ShutdownConfig::default(), phase: ShutdownPhase::Running }
}

///|
pub fn GracefulShutdown::new_with_config(
  host : AgentHost,
  config : ShutdownConfig,
) -> GracefulShutdown {
  { host, config, phase: ShutdownPhase::Running }
}

///|
pub fn GracefulShutdown::initiate(self : GracefulShutdown) -> Unit {
  self.phase = ShutdownPhase::Draining
}

///|
pub fn GracefulShutdown::drain(self : GracefulShutdown) -> Unit {
  // Deactivate all active agents
  let active_ids : Array[@core.AgentId] = []
  for key, _ in self.host.active {
    let id = @core.AgentId::create(key, "0.1.0", "livingtree/ltma")
    active_ids.push(id)
  }
  for id in active_ids {
    self.host.deactivate(id)
  }
  self.phase = ShutdownPhase::ShuttingDown
}

///|
pub fn GracefulShutdown::complete(self : GracefulShutdown) -> Unit {
  self.phase = ShutdownPhase::Complete
}

///|
pub fn GracefulShutdown::phase_name(self : GracefulShutdown) -> String {
  match self.phase {
    ShutdownPhase::Running => "running"
    ShutdownPhase::Draining => "draining"
    ShutdownPhase::ShuttingDown => "shutting_down"
    ShutdownPhase::Complete => "complete"
  }
}

///|
pub fn GracefulShutdown::is_complete(self : GracefulShutdown) -> Bool {
  self.phase is ShutdownPhase::Complete
}
