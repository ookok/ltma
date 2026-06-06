///|
/// Shell tool — execute commands (native only, requires async runtime).

///|
pub fn execute_shell(command : String) -> String {
  "[shell: would execute '\{command}']"
}

///|
pub fn shell_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "shell", "Execute a shell command and return stdout + stderr", "{type:object,properties:{command:{type:string}}}",
    false,
  )
}
