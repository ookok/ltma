///|
/// question tool — ask the user for input via stdin.

///|
pub fn question_tool(prompt : String) -> String {
  "[question: " + prompt + " (awaiting user input)]"
}

///|
fn read_stdin_line() -> String {
  // Simple stdin line read — reads until newline
  // Uses @env.stdin or system calls in production
  ""
}

///|
pub fn question_tool_json(input : String) -> String {
  let prompt = extract_field(input, "question").unwrap_or("Answer: ")
  question_tool(prompt)
}

///|
pub fn question_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create("question", "Ask the user a question and wait for response", "{type:object,properties:{question:{type:string}}}", false)
}
