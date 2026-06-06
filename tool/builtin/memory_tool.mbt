///|
/// Memory tool — in-context key-value storage for agents.

///|
pub fn mem_store(key : String, value : String) -> String {
  "stored: " + key
}

///|
pub fn mem_recall(key : String) -> String {
  "recall: " + key
}

///|
fn mem_store_json(input : String) -> String {
  let key = extract_field(input, "key")
  let value = extract_field(input, "value")
  match (key, value) {
    (Some(k), Some(v)) => mem_store(k, v)
    _ => "error: missing 'key' or 'value'"
  }
}

///|
fn mem_recall_json(input : String) -> String {
  let key = extract_field(input, "key")
  match key {
    Some(k) => mem_recall(k)
    None => "error: missing 'key'"
  }
}

///|
pub fn mem_tool_def(name : String, desc : String) -> @core.ToolDefinition {
  @core.ToolDefinition::create(name, desc, "{type:object,properties:{key:{type:string},value:{type:string}}}", false)
}
