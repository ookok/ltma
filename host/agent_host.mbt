///|
/// AgentHost — the central orchestrator.

///|
pub struct AgentHost {
  catalog : AgentCatalog
  bus : EventBus
  active : Map[String, ActivationResult]
}

///|
pub fn AgentHost::new() -> AgentHost {
  { catalog: AgentCatalog::new(), bus: EventBus::new(), active: Map([]) }
}

///|
pub fn AgentHost::register(
  self : AgentHost,
  metadata : @core.AgentMetadata,
  factory : () -> @core.AgentHandle,
) -> Unit {
  self.catalog.register(metadata, factory)
  self.bus.publish(HostEvent::AgentRegistered(metadata.id))
}

///|
pub fn AgentHost::activate(
  self : AgentHost,
  agent_id : @core.AgentId,
) -> @pipeline.HostAdapter? {
  let reg = self.catalog.resolve(agent_id)
  if reg is Some(_) {
    let r = reg.unwrap()
    let result = activate_in_process(r.factory, agent_id)
    let key = agent_id.to_string()
    self.active[key] = result
    self.bus.publish(HostEvent::AgentActivated(agent_id))
    Some(result.adapter)
  } else {
    None
  }
}

///|
pub fn AgentHost::deactivate(
  self : AgentHost,
  agent_id : @core.AgentId,
) -> Unit {
  let key = agent_id.to_string()
  let r = self.active.get(key)
  if r is Some(_) {
    let val = r.unwrap()
    deactivate(val)
    self.active.remove(key)
    self.bus.publish(HostEvent::AgentDeactivated(agent_id))
  }
}

///|
pub fn AgentHost::send(
  self : AgentHost,
  agent_id : @core.AgentId,
  msg : @core.Message,
) -> @core.Message? {
  let key = agent_id.to_string()
  match self.active.get(key) {
    Some(r) => {
      self.bus.publish(HostEvent::AgentMessageSent(agent_id, msg))
      let response = r.adapter.call(msg)
      self.bus.publish(HostEvent::AgentMessageReceived(agent_id, response))
      Some(response)
    }
    None => None
  }
}

///|
pub fn AgentHost::list_registered(
  self : AgentHost,
) -> Array[@core.AgentMetadata] {
  self.catalog.list()
}
