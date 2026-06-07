///|
/// Plugin Loader — dynamic loading of agent plugins from filesystem.

///|
/// PluginSource — where a plugin is located.
pub enum PluginSource {
  File(String)
  Directory(String)
  Package(String)
}

///|
/// PluginInfo — metadata about a loaded plugin.
pub struct PluginInfo {
  name : String
  version : String
  source : PluginSource
  mut loaded : Bool
}

///|
pub fn PluginInfo::new(
  name : String,
  version : String,
  source : PluginSource,
) -> PluginInfo {
  { name, version, source, loaded: false }
}

///|
/// PluginLoader — scans and loads agent plugins.
pub struct PluginLoader {
  loaded : Map[String, PluginInfo]
  catalog : AgentCatalog
}

///|
pub fn PluginLoader::new(catalog : AgentCatalog) -> PluginLoader {
  { loaded: Map([]), catalog }
}

///|
pub fn PluginLoader::scan(
  self : PluginLoader,
  source : PluginSource,
) -> Array[PluginInfo] {
  match source {
    PluginSource::File(path) => {
      let mtime = get_mtime(path)
      if mtime < 0L {
        []
      } else {
        let info = PluginInfo::new(path, "0.0.0", source)
        [info]
      }
    }
    PluginSource::Directory(path) => {
      let names = list_dir(path)
      let result : Array[PluginInfo] = []
      for name in names {
        if name.has_suffix(".mbt") || name.has_suffix(".wasm") {
          let full = path + "/" + name
          result.push(PluginInfo::new(name, "0.0.0", PluginSource::File(full)))
        }
      }
      result
    }
    PluginSource::Package(_pkg) => []
  }
}

///|
pub fn PluginLoader::load(
  self : PluginLoader,
  info : PluginInfo,
  factory : () -> @core.AgentHandle,
  meta : @core.AgentMetadata,
) -> Unit {
  let key = info.name + "@" + info.version
  if self.loaded.contains(key) {
    return
  }
  info.loaded = true
  self.loaded[key] = info
  self.catalog.register(meta, factory)
}

///|
pub fn PluginLoader::unload(
  self : PluginLoader,
  name : String,
  version : String,
) -> Unit {
  self.loaded.remove(name + "@" + version)
}

///|
pub fn PluginLoader::list_loaded(self : PluginLoader) -> Array[PluginInfo] {
  let result : Array[PluginInfo] = []
  for _, info in self.loaded {
    result.push(info)
  }
  result
}

///|
pub fn PluginLoader::count_loaded(self : PluginLoader) -> Int {
  self.loaded.length()
}
