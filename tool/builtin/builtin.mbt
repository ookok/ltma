///|
/// Built-in tools for the LTMA framework.

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
  reg.register(write_tool_def(), fn(input) {
    // input is JSON: {"path": "...", "content": "..."}
    write_file(input, "")
  })
  reg.register(edit_tool_def(), fn(input) { edit_file(input, "", "") })
  reg.register(ls_tool_def(), list_directory)
  reg.register(stat_tool_def(), path_stat)
}
