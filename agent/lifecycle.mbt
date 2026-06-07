///|
/// Agent lifecycle event hooks.

///|
pub enum LifecycleEvent {
  BeforeInit
  AfterInit
  BeforeRun
  AfterRun
  BeforeShutdown
  AfterShutdown
  OnError(String)
}

///|
pub fn LifecycleEvent::before_init() -> LifecycleEvent {
  LifecycleEvent::BeforeInit
}

///|
pub fn LifecycleEvent::after_init() -> LifecycleEvent {
  LifecycleEvent::AfterInit
}

///|
pub fn LifecycleEvent::before_run() -> LifecycleEvent {
  LifecycleEvent::BeforeRun
}

///|
pub fn LifecycleEvent::after_run() -> LifecycleEvent {
  LifecycleEvent::AfterRun
}

///|
pub fn LifecycleEvent::before_shutdown() -> LifecycleEvent {
  LifecycleEvent::BeforeShutdown
}

///|
pub fn LifecycleEvent::after_shutdown() -> LifecycleEvent {
  LifecycleEvent::AfterShutdown
}

///|
pub fn LifecycleEvent::on_error(msg : String) -> LifecycleEvent {
  LifecycleEvent::OnError(msg)
}

///|
pub type LifecycleHook = (LifecycleEvent, @core.AgentId) -> Unit

///|
pub struct LifecycleHooks {
  hooks : Array[LifecycleHook]
}

///|
pub fn LifecycleHooks::new() -> LifecycleHooks {
  { hooks: [] }
}

///|
pub fn LifecycleHooks::add(self : LifecycleHooks, hook : LifecycleHook) -> Unit {
  self.hooks.push(hook)
}

///|
pub fn LifecycleHooks::fire(
  self : LifecycleHooks,
  event : LifecycleEvent,
  agent_id : @core.AgentId,
) -> Unit {
  for h in self.hooks {
    h(event, agent_id)
  }
}

///|
/// Logging hook — prints lifecycle events to stdout.
pub fn create_logging_hook() -> LifecycleHook {
  fn(event, id) {
    let name = match event {
      LifecycleEvent::BeforeInit => "before_init"
      LifecycleEvent::AfterInit => "after_init"
      LifecycleEvent::BeforeRun => "before_run"
      LifecycleEvent::AfterRun => "after_run"
      LifecycleEvent::BeforeShutdown => "before_shutdown"
      LifecycleEvent::AfterShutdown => "after_shutdown"
      LifecycleEvent::OnError(_) => "on_error"
    }
    println("[lifecycle] \{name} for \{id.to_string()}")
  }
}
