///|
/// webfetch tool — fetch URL content via HTTP GET.

///|
pub fn webfetch_tool(url : String) -> String {
  // Use @async_http.get for real HTTP fetching
  // For sync context, return a stub
  "[webfetch " + url + "]"
}

///|
pub fn webfetch_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create("webfetch", "Fetch a URL and return its text content", "{type:object,properties:{url:{type:string}}}", false)
}
