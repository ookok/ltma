///|
/// AddInStore — persistent add-in metadata store (MAF AddInStore equivalent).
///
/// In MAF, AddInStore is a system-store of all known add-ins, their
/// pipeline versions, locations, and activation data. This allows
/// offline discovery and fast re-activation without re-scanning.

///|
/// AddInRecord — a persisted add-in entry.
pub struct AddInRecord {
  agent_id : @core.AgentId
  metadata : @core.AgentMetadata
  pipeline_version : String
  assembly_path : String
  enabled : Bool
}

///|
pub fn AddInRecord::new(
  agent_id : @core.AgentId,
  metadata : @core.AgentMetadata,
  pipeline_version : String,
  assembly_path : String,
  enabled : Bool,
) -> AddInRecord {
  { agent_id, metadata, pipeline_version, assembly_path, enabled }
}

///|
/// AddInStore — persistent in-memory store of add-in records.
pub struct AddInStore {
  entries : Map[String, AddInRecord]
}

///|
pub fn AddInStore::new() -> AddInStore {
  { entries: Map([]) }
}

///|
pub fn AddInStore::store(self : AddInStore, record : AddInRecord) -> Unit {
  let key = record.agent_id.to_string()
  self.entries[key] = record
}

///|
pub fn AddInStore::resolve(
  self : AddInStore,
  agent_id : @core.AgentId,
) -> AddInRecord? {
  self.entries.get(agent_id.to_string())
}

///|
pub fn AddInStore::list(self : AddInStore) -> Array[AddInRecord] {
  let result : Array[AddInRecord] = []
  for _, rec in self.entries {
    result.push(rec)
  }
  result
}

///|
pub fn AddInStore::remove(self : AddInStore, agent_id : @core.AgentId) -> Unit {
  self.entries.remove(agent_id.to_string())
}

///|
pub fn AddInStore::enable(self : AddInStore, agent_id : @core.AgentId) -> Unit {
  let key = agent_id.to_string()
  match self.entries.get(key) {
    Some(rec) =>
      self.entries[key] = AddInRecord::new(
        rec.agent_id,
        rec.metadata,
        rec.pipeline_version,
        rec.assembly_path,
        true,
      )
    None => ()
  }
}

///|
pub fn AddInStore::disable(self : AddInStore, agent_id : @core.AgentId) -> Unit {
  let key = agent_id.to_string()
  match self.entries.get(key) {
    Some(rec) =>
      self.entries[key] = AddInRecord::new(
        rec.agent_id,
        rec.metadata,
        rec.pipeline_version,
        rec.assembly_path,
        false,
      )
    None => ()
  }
}

///|
pub fn AddInStore::count(self : AddInStore) -> Int {
  self.entries.length()
}

///|
/// AddInStoreManager — manages discovery → store → catalog pipeline.
pub struct AddInStoreManager {
  store : AddInStore
  catalog : AgentCatalog
}

///|
pub fn AddInStoreManager::new() -> AddInStoreManager {
  { store: AddInStore::new(), catalog: AgentCatalog::new() }
}

///|
pub fn AddInStoreManager::import_discovered(
  self : AddInStoreManager,
  result : DiscoveryResult,
  factory_fn : (AgentManifest) -> @core.AgentHandle,
) -> Int {
  let mut count = 0
  for manifest in result.manifests {
    let meta = manifest.to_metadata()
    let key = meta.id.to_string()
    if self.store.entries.contains(key) {
      continue
    }
    let record = AddInRecord::new(meta.id, meta, "1.0.0", "", true)
    self.store.store(record)
    let factory = fn() { factory_fn(manifest) }
    self.catalog.register(meta, factory)
    count = count + 1
  }
  count
}

///|
pub fn AddInStoreManager::store(self : AddInStoreManager) -> AddInStore {
  self.store
}

///|
pub fn AddInStoreManager::catalog(self : AddInStoreManager) -> AgentCatalog {
  self.catalog
}
