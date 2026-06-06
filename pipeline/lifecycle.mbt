///|
/// Lifecycle management for agents.

///|
fn valid_transition(from : @core.AgentStatus, to : @core.AgentStatus) -> Bool {
  match (from.code, to.code) {
    (0, 1) | (0, 6) => true
    (1, 2) | (1, 6) => true
    (2, 3) | (2, 7) => true
    (3, 4) | (3, 6) => true
    (4, 5) | (4, 3) | (4, 7) => true
    (5, 3) | (5, 6) => true
    (7, 3) | (7, 6) => true
    (6, _) => false
    _ => false
  }
}

///|
pub struct LifecycleManager {
  mut st : @core.AgentStatus
  mut last_error : String?
}

///|
pub fn LifecycleManager::new() -> LifecycleManager {
  { st: @core.AgentStatus::new_st(), last_error: None }
}

///|
pub fn LifecycleManager::status(self : LifecycleManager) -> @core.AgentStatus {
  self.st
}

///|
pub fn LifecycleManager::transition(
  self : LifecycleManager,
  target : @core.AgentStatus,
) -> Unit {
  if valid_transition(self.st, target) {
    self.st = target
    if target.is_error() {
      self.last_error = target.message
    }
  }
}

///|
pub fn LifecycleManager::reset(self : LifecycleManager) -> Unit {
  self.st = @core.AgentStatus::new_st()
  self.last_error = None
}
