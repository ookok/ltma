///|
/// Git tool — execute git commands via shell.

///|
pub fn execute_git(git_cmd : String) -> String {
  let cmd = "git " + git_cmd + " 2>&1"
  let cmd_bytes = @encoding/utf8.encode(cmd)
  let result_bytes = _shell_exec(cmd_bytes)
  if result_bytes.length() == 0 {
    "[git: no output]"
  } else {
    @encoding/utf8.decode_lossy(result_bytes)
  }
}

///|
pub fn git_tool_json(input : String) -> String {
  let command = extract_field(input, "command").unwrap_or("")
  if command == "" {
    return "error: missing 'command' field (e.g. {\"command\":\"status\"})"
  }
  execute_git(command)
}

///|
pub fn git_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "git", "Execute a git command (e.g. 'status', 'log --oneline -5', 'diff', 'branch'). Runs 'git <command>' in the repository root.",
    "{type:object,properties:{command:{type:string}}}", false,
  )
}
