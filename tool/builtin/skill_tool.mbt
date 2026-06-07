///|
/// skill tool — load knowledge/skill files.

///|
pub fn skill_load(path : String) -> String {
  let content = @xfs.read_file_to_string(path) catch {
    _ => return "error: cannot read " + path
  }
  "skill loaded (" + content.length().to_string() + " chars) from " + path
}

///|
pub fn skill_tool_json(input : String) -> String {
  let path = extract_field(input, "path").unwrap_or("")
  if path == "" {
    "error: missing 'path'"
  } else {
    skill_load(path)
  }
}

///|
pub fn skill_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "skill", "Load a skill/knowledge file for context", "{type:object,properties:{path:{type:string}}}",
    false,
  )
}
