///|
/// Config system — hierarchical configuration with runtime reload support.

///|
/// ConfigValue — a single configuration value with type-safe access.
pub struct ConfigValue {
  value : String
}

///|
pub fn ConfigValue::new(value : String) -> ConfigValue {
  { value, }
}

///|
pub fn ConfigValue::as_string(self : ConfigValue) -> String {
  self.value
}

///|
pub fn ConfigValue::as_int(self : ConfigValue) -> Int? {
  // TODO: use proper int parsing when available in MoonBit stdlib
  None
}

///|
pub fn ConfigValue::as_bool(self : ConfigValue) -> Bool {
  self.value == "true" || self.value == "1" || self.value == "yes"
}

///|
/// ConfigSection — a named group of configuration values.
pub struct ConfigSection {
  name : String
  values : Map[String, ConfigValue]
  children : Map[String, ConfigSection]
}

///|
pub fn ConfigSection::new(name : String) -> ConfigSection {
  { name, values: Map([]), children: Map([]) }
}

///|
pub fn ConfigSection::set(
  self : ConfigSection,
  key : String,
  value : String,
) -> Unit {
  self.values[key] = ConfigValue::new(value)
}

///|
pub fn ConfigSection::get(self : ConfigSection, key : String) -> ConfigValue? {
  self.values.get(key)
}

///|
pub fn ConfigSection::section(
  self : ConfigSection,
  name : String,
) -> ConfigSection? {
  self.children.get(name)
}

///|
/// Config — the top-level configuration container.
pub struct Config {
  root : ConfigSection
}

///|
pub fn Config::new() -> Config {
  { root: ConfigSection::new("root") }
}

///|
pub fn Config::section(self : Config, path : String) -> ConfigSection? {
  let parts = path.split("/")
  let mut current = self.root
  for p in parts {
    let p_owned = p.to_owned()
    match current.children.get(p_owned) {
      Some(child) => current = child
      None => return None
    }
  }
  Some(current)
}

///|
pub fn Config::set(
  self : Config,
  path : String,
  key : String,
  value : String,
) -> Unit {
  let parts = path.split("/")
  let mut current = self.root
  for p in parts {
    let p_owned = p.to_owned()
    match current.children.get(p_owned) {
      Some(child) => current = child
      None => {
        let new_section = ConfigSection::new(p_owned)
        current.children[p_owned] = new_section
        current = new_section
      }
    }
  }
  current.set(key, value)
}

///|
pub fn Config::get(
  self : Config,
  section_path : String,
  key : String,
) -> ConfigValue? {
  match self.section(section_path) {
    Some(s) => s.get(key)
    None => None
  }
}

///|
/// ConfigWatcher — callback-based configuration reload.
pub type ConfigWatcher = (Config) -> Unit

///|
/// ConfigManager — manages config lifecycle and hot-reload watchers.
pub struct ConfigManager {
  mut config : Config
  watchers : Array[ConfigWatcher]
}

///|
pub fn ConfigManager::new(config : Config) -> ConfigManager {
  { config, watchers: [] }
}

///|
pub fn ConfigManager::reload(self : ConfigManager, new_config : Config) -> Unit {
  self.config = new_config
  for watcher in self.watchers {
    watcher(new_config)
  }
}

///|
pub fn ConfigManager::watch(
  self : ConfigManager,
  watcher : ConfigWatcher,
) -> Unit {
  self.watchers.push(watcher)
}

///|
pub fn ConfigManager::config(self : ConfigManager) -> Config {
  self.config
}
