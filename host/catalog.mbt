///|
/// Agent registration catalog.

///|
pub struct AgentRegistration {
  metadata : @core.AgentMetadata
  factory : () -> @core.AgentHandle
}

///|
pub struct AgentCatalog {
  entries : Map[String, AgentRegistration]
}

///|
pub fn AgentCatalog::new() -> AgentCatalog {
  { entries: Map([]) }
}

///|
pub fn AgentCatalog::register(
  self : AgentCatalog,
  metadata : @core.AgentMetadata,
  factory : () -> @core.AgentHandle,
) -> Unit {
  let key = metadata.id.to_string()
  self.entries[key] = { metadata, factory }
}

///|
pub fn AgentCatalog::resolve(
  self : AgentCatalog,
  agent_id : @core.AgentId,
) -> AgentRegistration? {
  self.entries.get(agent_id.to_string())
}

///|
pub fn AgentCatalog::list(self : AgentCatalog) -> Array[@core.AgentMetadata] {
  let result : Array[@core.AgentMetadata] = []
  for _, reg in self.entries {
    result.push(reg.metadata)
  }
  result
}

///|
pub fn AgentCatalog::contains(
  self : AgentCatalog,
  agent_id : @core.AgentId,
) -> Bool {
  self.entries.contains(agent_id.to_string())
}

///|
pub fn AgentCatalog::count(self : AgentCatalog) -> Int {
  self.entries.length()
}
