///|
/// Tool registry — register, discover, and execute tools.

///|
pub struct ToolEntry {
  def : @core.ToolDefinition
  execute_fn : (String) -> String
}

///|
pub struct ToolRegistry {
  entries : Map[String, ToolEntry]
}

///|
pub fn ToolRegistry::new() -> ToolRegistry {
  { entries: Map([]) }
}

///|
pub fn ToolRegistry::register(
  self : ToolRegistry,
  def : @core.ToolDefinition,
  execute_fn : (String) -> String,
) -> Unit {
  self.entries[def.name] = { def, execute_fn }
}

///|
pub fn ToolRegistry::resolve(self : ToolRegistry, name : String) -> ToolEntry? {
  self.entries.get(name)
}

///|
pub fn ToolRegistry::execute(
  self : ToolRegistry,
  name : String,
  input : String,
) -> String? {
  match self.entries.get(name) {
    Some(entry) => Some((entry.execute_fn)(input))
    None => None
  }
}

///|
pub fn ToolRegistry::list_defs(
  self : ToolRegistry,
) -> Array[@core.ToolDefinition] {
  let result : Array[@core.ToolDefinition] = []
  for _, entry in self.entries {
    result.push(entry.def)
  }
  result
}

///|
pub fn ToolRegistry::count(self : ToolRegistry) -> Int {
  self.entries.length()
}
