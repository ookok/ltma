///|
/// Agent discovery — MAF-style directory scanning for add-in manifests.

///|
/// DiscoverySource — where to look for agents.
pub enum DiscoverySource {
  Directory(String)
  Package(String)
  Inline
}

///|
/// AgentManifest — metadata describing an agent package.
pub struct AgentManifest {
  name : String
  version : String
  description : String
  capabilities : Array[String]
  isolation : String
  target : String
}

///|
pub fn AgentManifest::to_metadata(self : AgentManifest) -> @core.AgentMetadata {
  let id = @core.AgentId::create(self.name, self.version, "livingtree/ltma")
  let level = if self.isolation == "wasm" {
    @core.IsolationLevel::wasm_sandbox()
  } else if self.isolation == "process" {
    @core.IsolationLevel::process()
  } else {
    @core.IsolationLevel::in_process()
  }
  let target = if self.target == "wasm" {
    @core.Target::wasm()
  } else if self.target == "js" {
    @core.Target::js()
  } else {
    @core.Target::native()
  }
  @core.AgentMetadata::create(
    id,
    self.description,
    self.capabilities,
    level,
    target,
    self.version,
  )
}

///|
/// DiscoveryResult — the result of scanning a discovery source.
pub struct DiscoveryResult {
  source : DiscoverySource
  manifests : Array[AgentManifest]
  errors : Array[String]
}

///|
pub fn DiscoveryResult::new(
  source : DiscoverySource,
  manifests : Array[AgentManifest],
  errors : Array[String],
) -> DiscoveryResult {
  { source, manifests, errors }
}

///|
/// Discover agents from a discovery source.
pub fn discover(source : DiscoverySource) -> DiscoveryResult {
  match source {
    DiscoverySource::Inline => inline_discovery()
    DiscoverySource::Directory(path) => directory_discovery(path)
    DiscoverySource::Package(_pkg) => package_discovery()
  }
}

///|
fn inline_discovery() -> DiscoveryResult {
  DiscoveryResult::new(DiscoverySource::Inline, [], [])
}

///|
fn directory_discovery(_path : String) -> DiscoveryResult {
  // TODO: scan directory for moon.pkg or manifest files
  // For now, return empty with a note
  DiscoveryResult::new(DiscoverySource::Directory(_path), [], [
    "directory scanning not yet implemented",
  ])
}

///|
fn package_discovery() -> DiscoveryResult {
  // TODO: query mooncakes.io or local package cache
  DiscoveryResult::new(DiscoverySource::Package(""), [], [
    "package discovery not yet implemented",
  ])
}

///|
/// Register discovered agents into a catalog.
pub fn register_discovered(
  catalog : AgentCatalog,
  result : DiscoveryResult,
  factory_fn : (AgentManifest) -> @core.AgentHandle,
) -> Int {
  let mut count = 0
  for manifest in result.manifests {
    let meta = manifest.to_metadata()
    let factory = fn() { factory_fn(manifest) }
    catalog.register(meta, factory)
    count = count + 1
  }
  count
}
