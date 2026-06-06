///|
/// Built-in tools for the LTMA framework.

///|
fn extract_field(json : String, field : String) -> String? {
  let search = "\"" + field + "\":\""
  match json.find(search) {
    Some(start) => {
      let val_start = start + search.length()
      let view = json.sub(start=val_start)
      match view.find("\"") {
        Some(end) => Some(view.sub(start=0, end~).to_owned())
        None => None
      }
    }
    None => None
  }
}

///|
pub fn register_builtins(reg : @tool.ToolRegistry) -> Unit {
  reg.register(
    @core.ToolDefinition::create(
      "echo", "Echo input back", "{type:object,properties:{input:{type:string}}}",
      false,
    ),
    fn(input) { "echo: \{input}" },
  )

  reg.register(
    @core.ToolDefinition::create(
      "greet", "Greet with a name", "{type:object,properties:{name:{type:string}}}",
      false,
    ),
    fn(input) { "Hello, \{input}!" },
  )

  reg.register(shell_tool_def(), execute_shell)
  reg.register(read_tool_def(), read_file)
  reg.register(write_tool_def(), write_file_json)
  reg.register(edit_tool_def(), edit_file_json)
  reg.register(ls_tool_def(), list_directory)
  reg.register(stat_tool_def(), path_stat)
}
