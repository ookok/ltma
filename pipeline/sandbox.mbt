///|
/// Isolation sandbox abstraction for Agent execution environments.

///|
/// Supported sandbox kinds.
pub enum SandboxKind {
  InProcess
  Wasm
  Process
}

///|
/// Sandbox configuration.
pub struct SandboxConfig {
  kind : SandboxKind
  memory_limit_mb : Int
  time_limit_ms : Int
  allowed_paths : Array[String]
  allowed_networks : Array[String]
}

///|
pub fn SandboxConfig::in_process() -> SandboxConfig {
  {
    kind: SandboxKind::InProcess,
    memory_limit_mb: 0,
    time_limit_ms: 0,
    allowed_paths: [],
    allowed_networks: [],
  }
}

///|
pub fn SandboxConfig::wasm(memory_mb : Int, time_ms : Int) -> SandboxConfig {
  {
    kind: SandboxKind::Wasm,
    memory_limit_mb: memory_mb,
    time_limit_ms: time_ms,
    allowed_paths: [],
    allowed_networks: [],
  }
}

///|
pub fn SandboxConfig::process(memory_mb : Int, time_ms : Int) -> SandboxConfig {
  {
    kind: SandboxKind::Process,
    memory_limit_mb: memory_mb,
    time_limit_ms: time_ms,
    allowed_paths: [],
    allowed_networks: [],
  }
}

///|
/// Sandbox — isolation context for running agents.
pub struct Sandbox {
  config : SandboxConfig
  mut active : Bool
}

///|
pub fn Sandbox::new(config : SandboxConfig) -> Sandbox {
  { config, active: false }
}

///|
pub fn Sandbox::start(self : Sandbox) -> Unit {
  self.active = true
}

///|
pub fn Sandbox::stop(self : Sandbox) -> Unit {
  self.active = false
}

///|
pub fn Sandbox::is_active(self : Sandbox) -> Bool {
  self.active
}

///|
pub fn Sandbox::config(self : Sandbox) -> SandboxConfig {
  self.config
}

///|
/// Create a sandbox based on the isolation level.
pub fn create_sandbox(level : @core.IsolationLevel) -> Sandbox {
  if level.code == 0 {
    Sandbox::new(SandboxConfig::in_process())
  } else if level.code == 1 {
    Sandbox::new(SandboxConfig::wasm(64, 30000))
  } else {
    Sandbox::new(SandboxConfig::process(256, 60000))
  }
}
