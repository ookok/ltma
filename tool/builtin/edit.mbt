///|
/// Edit tool — find-and-replace in a file.

///|
/// Edit a file by replacing old_string with new_string.
pub fn edit_file(
  path : String,
  old_string : String,
  new_string : String,
) -> String {
  "[edit_file would edit: \{path} (\{old_string.length()} -> \{new_string.length()} chars)]"
}

///|
pub fn edit_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    "edit", "Edit a file by finding and replacing text (first occurrence)", "{type:object,properties:{path:{type:string},old_string:{type:string},new_string:{type:string}}}",
    false,
  )
}
