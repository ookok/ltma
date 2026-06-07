///|
/// Feature flags — runtime-toggleable capabilities.

///|
/// FeatureFlag — a named feature with enabled/disabled state.
pub struct FeatureFlag {
  name : String
  mut enabled : Bool
  description : String
}

///|
pub fn FeatureFlag::new(
  name : String,
  enabled : Bool,
  description : String,
) -> FeatureFlag {
  { name, enabled, description }
}

///|
pub fn FeatureFlag::enable(self : FeatureFlag) -> Unit {
  self.enabled = true
}

///|
pub fn FeatureFlag::disable(self : FeatureFlag) -> Unit {
  self.enabled = false
}

///|
pub fn FeatureFlag::is_enabled(self : FeatureFlag) -> Bool {
  self.enabled
}

///|
/// FeatureFlags — centralized feature flag management.
pub struct FeatureFlags {
  flags : Map[String, FeatureFlag]
}

///|
pub fn FeatureFlags::new() -> FeatureFlags {
  { flags: Map([]) }
}

///|
pub fn FeatureFlags::register(self : FeatureFlags, flag : FeatureFlag) -> Unit {
  self.flags[flag.name] = flag
}

///|
pub fn FeatureFlags::is_enabled(self : FeatureFlags, name : String) -> Bool {
  match self.flags.get(name) {
    Some(f) => f.enabled
    None => false
  }
}

///|
pub fn FeatureFlags::enable(self : FeatureFlags, name : String) -> Unit {
  match self.flags.get(name) {
    Some(f) => f.enable()
    None => ()
  }
}

///|
pub fn FeatureFlags::disable(self : FeatureFlags, name : String) -> Unit {
  match self.flags.get(name) {
    Some(f) => f.disable()
    None => ()
  }
}

///|
pub fn FeatureFlags::list(self : FeatureFlags) -> Array[FeatureFlag] {
  let result : Array[FeatureFlag] = []
  for _, f in self.flags {
    result.push(f)
  }
  result
}

///|
pub fn FeatureFlags::count(self : FeatureFlags) -> Int {
  self.flags.length()
}

///|
/// Common feature flag names for the LTMA framework.
pub fn feature_streaming() -> String {
  "streaming"
}

///|
pub fn feature_experimental_tools() -> String {
  "experimental_tools"
}

///|
pub fn feature_dag_pipeline() -> String {
  "dag_pipeline"
}

///|
pub fn feature_async_agents() -> String {
  "async_agents"
}
