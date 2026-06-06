///|
/// Edit tool — find-and-replace in a file.

///|
pub fn edit_file(path : String, old_str : String, new_str : String) -> String {
  try {
    let content = @xfs.read_file_to_string(path)
    if !content.contains(old_str) {
      return "error: pattern not found in file"
    }
    let modified = content.replace(old=old_str, new=new_str)
    @xfs.write_string_to_file(path, modified)
    "ok: replaced 1 occurrence in \{path}"
  } catch {
    e => "error editing file: \{@debug.to_string(e)}"
  }
}

///|
fn edit_file_json(input : String) -> String {
  let path = extract_field(input, "path")
  let old_s = extract_field(input, "old_string")
  let new_s = extract_field(input, "new_string")
  match (path, old_s, new_s) {
    (Some(p), Some(o), Some(n)) => edit_file(p, o, n)
    _ =>
      "error: missing 'path', 'old_string', or 'new_string' in JSON arguments"
  }
}

///|
pub fn edit_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "edit", "Edit a file by finding and replacing text (first occurrence)", "{type:object,properties:{path:{type:string},old_string:{type:string},new_string:{type:string}}}",
    false,
  )
}
