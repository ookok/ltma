///|
/// Shell tool — execute commands via C FFI (_popen).

///|
#borrow(command)
extern "c" fn _shell_exec(command : Bytes) -> Bytes = "shell_exec"

///|
/// Execute a shell command and return its stdout output.
pub fn execute_shell(command : String) -> String {
  let cmd_bytes = @encoding/utf8.encode(command)
  let result_bytes = _shell_exec(cmd_bytes)
  if result_bytes.length() == 0 {
    "[shell: no output]"
  } else {
    @encoding/utf8.decode_lossy(result_bytes)
  }
}

///|
pub fn shell_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "shell", "Execute a shell command and return stdout", "{type:object,properties:{command:{type:string}}}",
    false,
  )
}
