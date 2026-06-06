///|
/// Write tool — write content to a file.

///|
pub fn write_file(path : String, content : String) -> String {
  try {
    @xfs.write_string_to_file(path, content)
    "ok: wrote \{content.length()} bytes to \{path}"
  } catch {
    e => "error writing file: \{@debug.to_string(e)}"
  }
}

///|
fn write_file_json(input : String) -> String {
  let path = extract_field(input, "path")
  let content = extract_field(input, "content")
  match (path, content) {
    (Some(p), Some(c)) => write_file(p, c)
    _ => "error: missing 'path' or 'content' in JSON arguments"
  }
}

///|
pub fn write_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "write", "Write content to a file (creates or overwrites)", "{type:object,properties:{path:{type:string},content:{type:string}}}",
    false,
  )
}
