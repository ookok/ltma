///|
/// Read tool — read file contents.

///|
/// Read a file and return its contents as a string.
pub fn read_file(path : String) -> String {
  "[read_file would read: \{path}]"
}

///|
pub fn read_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "read", "Read a file from the filesystem and return its contents", "{type:object,properties:{path:{type:string}}}",
    false,
  )
}
