///|
/// todowrite tool — simple task tracking (ephemeral).

///|
pub fn todo_add(item : String) -> String {
  "added: " + item
}

///|
pub fn todo_list(_args : String) -> String {
  "(todo list — ephemeral)"
}

///|
pub fn todo_done(index_str : String) -> String {
  "done: " + index_str
}

///|
pub fn todo_add_json(input : String) -> String {
  let item = extract_field(input, "item").unwrap_or("")
  if item == "" {
    "error: missing 'item'"
  } else {
    todo_add(item)
  }
}

///|
pub fn todo_def(name : String, desc : String) -> @core.ToolDefinition {
  @core.ToolDefinition::create(
    name, desc, "{type:object,properties:{item:{type:string}}}", false,
  )
}
