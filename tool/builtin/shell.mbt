///|
/// Shell tool — execute commands (native only, requires async runtime).

///|
/// Execute a shell command and return output.
pub fn execute_shell(command : String) -> String {
  // In production, use @async.process or C FFI
  // For now, return a stub response
  "[shell_exec would run: \{command}]"
}

///|
pub fn shell_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "shell", "Execute a shell command and return stdout + stderr", "{type:object,properties:{command:{type:string}}}",
    false,
  )
}
