///|
/// Agent metadata registry — central registration for agent types.

///|
pub struct AgentRegistration {
  metadata : @core.AgentMetadata
  factory : () -> @core.AgentHandle
}

///|
pub fn AgentRegistration::new(
  metadata : @core.AgentMetadata,
  factory : () -> @core.AgentHandle,
) -> AgentRegistration {
  { metadata, factory }
}

///|
pub struct AgentRegistry {
  entries : Map[String, AgentRegistration]
}

///|
pub fn AgentRegistry::new() -> AgentRegistry {
  { entries: Map([]) }
}

///|
pub fn AgentRegistry::register(
  self : AgentRegistry,
  metadata : @core.AgentMetadata,
  factory : () -> @core.AgentHandle,
) -> Unit {
  let key = metadata.id.to_string()
  self.entries[key] = AgentRegistration::new(metadata, factory)
}

///|
pub fn AgentRegistry::resolve(
  self : AgentRegistry,
  agent_id : @core.AgentId,
) -> AgentRegistration? {
  let key = agent_id.to_string()
  self.entries.get(key)
}

///|
pub fn AgentRegistry::list(self : AgentRegistry) -> Array[@core.AgentMetadata] {
  let result : Array[@core.AgentMetadata] = []
  for _, reg in self.entries {
    result.push(reg.metadata)
  }
  result
}

///|
pub fn AgentRegistry::count(self : AgentRegistry) -> Int {
  self.entries.length()
}

///|
pub fn AgentRegistry::unregister(
  self : AgentRegistry,
  agent_id : @core.AgentId,
) -> Unit {
  let key = agent_id.to_string()
  self.entries.remove(key)
}
