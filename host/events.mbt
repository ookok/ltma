///|
/// Event system for host-level notifications.

///|
pub enum HostEvent {
  AgentRegistered(@core.AgentId)
  AgentUnregistered(@core.AgentId)
  AgentActivated(@core.AgentId)
  AgentDeactivated(@core.AgentId)
  AgentMessageSent(@core.AgentId, @core.Message)
  AgentMessageReceived(@core.AgentId, @core.Message)
  System(String)
}

///|
pub type EventHandler = (HostEvent) -> Unit

///|
pub struct EventBus {
  handlers : Array[EventHandler]
}

///|
pub fn EventBus::new() -> EventBus {
  { handlers: [] }
}

///|
pub fn EventBus::subscribe(self : EventBus, handler : EventHandler) -> Unit {
  self.handlers.push(handler)
}

///|
pub fn EventBus::publish(self : EventBus, event : HostEvent) -> Unit {
  for h in self.handlers {
    h(event)
  }
}
