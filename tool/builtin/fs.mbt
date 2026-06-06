///|
/// FS tool — file system operations (list dir, check file, etc.).

///|
pub fn list_directory(path : String) -> String {
  try {
    let entries = @xfs.read_dir(path)
    let mut result = ""
    for i = 0; i < entries.length(); i = i + 1 {
      if i > 0 {
        result = result + "\n"
      }
      result = result + entries[i]
    }
    "entries (\{path}):\n\{result}"
  } catch {
    e => "error listing directory: \{@debug.to_string(e)}"
  }
}

///|
pub fn path_stat(path : String) -> String {
  let exists = @xfs.path_exists(path)
  if !exists {
    return "path: \{path}\nstatus: not found"
  }
  try {
    let is_file = @xfs.is_file(path)
    let is_dir = @xfs.is_dir(path)
    let kind = if is_file {
      "file"
    } else if is_dir {
      "directory"
    } else {
      "other"
    }
    "path: \{path}\ntype: \{kind}"
  } catch {
    e => "error checking path: \{@debug.to_string(e)}"
  }
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
