///|
/// Preset prompt templates for common agent scenarios.

///|
/// Default assistant system prompt.
pub fn default_system_prompt() -> String {
  "You are a helpful AI assistant. You have access to tools that let you " +
  "read and write files, execute commands, and search the web. " +
  "Use these tools when they help answer the user's request. " +
  "Think step by step. When using tools, explain what you're doing. " +
  "If you don't know something, say so."
}

///|
/// Code assistant system prompt.
pub fn code_system_prompt(workspace : String) -> String {
  "You are an expert programming assistant. Your workspace is " +
  workspace +
  ". " +
  "You can read, write, and edit files using the available tools. " +
  "Provide clear, well-commented code following best practices. " +
  "When writing code, explain your approach first, then implement. " +
  "If you need to test code, use the shell tool."
}

///|
/// Research assistant system prompt.
pub fn research_system_prompt() -> String {
  "You are a research assistant. You can search the web and read files " +
  "to gather information. Synthesize information from multiple sources " +
  "into clear, well-organized answers. Cite your sources when possible. " +
  "If sources are insufficient, state what is known and identify gaps. " +
  "Be objective and balanced in your analysis."
}

///|
/// Tool description prompt — generates a summary of available tools.
pub fn tool_context_prompt(registry : @tool.ToolRegistry) -> String {
  let defs = registry.list_defs()
  if defs.length() == 0 {
    return ""
  }
  let mut result = "Available tools:\n"
  for d in defs {
    result = result + "- " + d.name + ": " + d.description + "\n"
  }
  result
}

///|
/// Format conversation history for context injection.
pub fn history_context(messages : Array[String]) -> String {
  if messages.length() == 0 {
    return ""
  }
  let mut result = "Conversation history:\n"
  for i = 0; i < messages.length(); i = i + 1 {
    let role = if i % 2 == 0 { "User" } else { "Assistant" }
    result = result + role + ": " + messages[i] + "\n"
  }
  result
}

///|
/// Knowledge base context prompt.
pub fn knowledge_context(results : Array[String]) -> String {
  if results.length() == 0 {
    return ""
  }
  let mut result = "Relevant context from knowledge base:\n"
  for i = 0; i < results.length(); i = i + 1 {
    result = result + (i + 1).to_string() + ". " + results[i] + "\n"
  }
  result
}
