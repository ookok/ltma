///|
/// Read tool — read file contents.

///|
pub fn read_file(path : String) -> String {
  @xfs.read_file_to_string(path) catch {
    e => "error reading file: \{@debug.to_string(e)}"
  }
}

///|
pub fn read_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "read", "Read a file from the filesystem and return its contents", "{type:object,properties:{path:{type:string}}}",
    false,
  )
}
