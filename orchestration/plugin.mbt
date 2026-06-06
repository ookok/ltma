///|
/// Plugin system — dynamic agent loading via package registration.

///|
/// Plugin descriptor.
pub struct Plugin {
  name : String
  version : String
  description : String
}

///|
pub fn Plugin::new(name : String, version : String, description : String) -> Plugin {
  { name, version, description }
}

///|
/// Plugin registry — manages loaded plugins.
pub struct PluginRegistry {
  plugins : Map[String, Plugin]
}

///|
pub fn PluginRegistry::new() -> PluginRegistry {
  { plugins: Map([]) }
}

///|
pub fn PluginRegistry::register(self : PluginRegistry, plugin : Plugin) -> Unit {
  self.plugins[plugin.name] = plugin
}

///|
pub fn PluginRegistry::list(self : PluginRegistry) -> Array[Plugin] {
  let result : Array[Plugin] = []
  for _, p in self.plugins { result.push(p) }
  result
}

///|
pub fn PluginRegistry::count(self : PluginRegistry) -> Int {
  self.plugins.length()
}
