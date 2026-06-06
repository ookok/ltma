///|
/// Built-in tools for the LTMA framework.

///|
fn extract_field(json : String, field : String) -> String? {
  let search = "\"" + field + "\":\""
  match json.find(search) {
    Some(start) => {
      let val_start = start + search.length()
      let view = json.sub(start=val_start)
      match view.find("\"") {
        Some(end) => Some(view.sub(start=0, end~).to_owned())
        None => None
      }
    }
    None => None
  }
}

///|
pub fn register_builtins(reg : @tool.ToolRegistry) -> Unit {
  // Communication
  reg.register(shell_tool_def(), execute_shell)
  reg.register(fetch_tool_def(), fetch_url)

  // File I/O
  reg.register(read_tool_def(), read_file)
  reg.register(write_tool_def(), write_file_json)
  reg.register(edit_tool_def(), edit_file_json)
  reg.register(ls_tool_def(), list_directory)
  reg.register(stat_tool_def(), path_stat)

  // Utilities
  reg.register(math_tool_def(), math_eval)
  reg.register(datetime_tool_def(), get_datetime)
  reg.register(random_tool_def(), fn(_) { random_number(100).to_string() })

  // Encoding
  reg.register(codec_tool_def("base64_encode", "Encode a string to base64"), base64_encode)
  reg.register(codec_tool_def("base64_decode", "Decode a base64 string"), base64_decode)
  reg.register(codec_tool_def("json_format", "Format and validate a JSON string"), json_format)
  reg.register(codec_tool_def("uuid", "Generate a UUID v4"), uuid_gen)
  reg.register(codec_tool_def("hash", "Compute a hash of the input"), hash_compute)

  // Agent memory
  reg.register(mem_tool_def("mem_store", "Store a value in agent memory"), mem_store_json)
  reg.register(mem_tool_def("mem_recall", "Recall a value from agent memory"), mem_recall_json)

  // Demo
  reg.register(
    @core.ToolDefinition::create("echo", "Echo input back", "{type:object,properties:{input:{type:string}}}", false),
    fn(input) { "echo: \{input}" },
  )
  reg.register(
    @core.ToolDefinition::create("greet", "Greet with a name", "{type:object,properties:{name:{type:string}}}", false),
    fn(input) { "Hello, \{input}!" },
  )
}
