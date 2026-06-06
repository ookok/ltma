///|
/// Write tool — write content to a file.

///|
/// Write content to a file. Returns success status.
pub fn write_file(path : String, content : String) -> String {
  "[write_file would write to: \{path} (\{content.length()} chars)]"
}

///|
pub fn write_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "write", "Write content to a file (creates or overwrites)", "{type:object,properties:{path:{type:string},content:{type:string}}}",
    false,
  )
}
