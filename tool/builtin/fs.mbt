///|
/// FS tool — file system operations (list dir, check file, etc.).

///|
/// List directory contents.
pub fn list_directory(path : String) -> String {
  "[list_directory would list: \{path}]"
}

///|
/// Check if a path exists and return its type (file/dir).
pub fn path_stat(path : String) -> String {
  "[path_stat would stat: \{path}]"
}

///|
pub fn ls_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "ls", "List directory contents", "{type:object,properties:{path:{type:string}}}",
    false,
  )
}

///|
pub fn stat_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "stat", "Get file/directory metadata (exists, type, size)", "{type:object,properties:{path:{type:string}}}",
    false,
  )
}
