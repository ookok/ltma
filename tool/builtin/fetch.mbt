///|
/// HTTP fetch tool — GET/POST URLs.

///|
pub fn fetch_url(url : String) -> String {
  "[fetch: would GET " + url + "]"
}

///|
pub fn fetch_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create("fetch", "Fetch a URL and return its content", "{type:object,properties:{url:{type:string}}}", false)
}
