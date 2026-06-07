///|
/// grep tool — search file contents for a pattern.

///|
pub fn grep_tool(pattern : String, path : String) -> String {
  let content = @xfs.read_file_to_string(path) catch {
    _ => return "error reading: " + path
  }
  let lower_pattern = pattern.to_lower()
  let lines = content.split("\n")
  let mut result = ""
  let mut count = 0
  for line in lines {
    let text = line.to_owned()
    if text.to_lower().contains(lower_pattern) {
      count = count + 1
      result = result + text + "\n"
    }
  }
  if count == 0 {
    "no matches in " + path
  } else {
    count.to_string() + " matches in " + path + ":\n" + result
  }
}

///|
pub fn grep_tool_json(input : String) -> String {
  let pattern = extract_field(input, "pattern").unwrap_or("")
  let path = extract_field(input, "path").unwrap_or(".")
  if pattern == "" {
    return "error: missing 'pattern'"
  }
  grep_tool(pattern, path)
}

///|
pub fn grep_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "grep", "Search for a pattern in a file (case-insensitive)", "{type:object,properties:{pattern:{type:string},path:{type:string}}}",
    false,
  )
}
