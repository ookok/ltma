///|
/// Prompt template engine — variable substitution and structured prompts.

///|
/// A prompt template with `{variable}` placeholders.
pub struct PromptTemplate {
  template : String
}

///|
pub fn PromptTemplate::new(template : String) -> PromptTemplate {
  { template }
}

///|
/// Render the template by substituting variables.
/// Variables are provided as key-value pairs.
pub fn PromptTemplate::render(self : PromptTemplate, vars : Map[String, String]) -> String {
  let mut result = self.template
  for k, v in vars {
    result = result.replace(old="{" + k + "}", new=v)
  }
  result
}

///|
/// Prompt role enum.
pub enum PromptRole {
  System
  User
  Assistant
  Tool
}

///|
/// A single prompt entry with role and content.
pub struct PromptEntry {
  role : PromptRole
  content : String
}

///|
pub fn PromptEntry::new(role : PromptRole, content : String) -> PromptEntry {
  { role, content }
}

///|
/// Prompt builder — constructs layered prompt sequences.
pub struct PromptBuilder {
  entries : Array[PromptEntry]
  system_prompt : String
  vars : Map[String, String]
}

///|
pub fn PromptBuilder::new(system_prompt : String) -> PromptBuilder {
  { entries: [], system_prompt, vars: Map([]) }
}

///|
pub fn PromptBuilder::with_var(
  self : PromptBuilder,
  key : String,
  value : String,
) -> PromptBuilder {
  self.vars[key] = value
  self
}

///|
pub fn PromptBuilder::add_system(
  self : PromptBuilder,
  content : String,
) -> PromptBuilder {
  self.entries.push(PromptEntry::new(PromptRole::System, content))
  self
}

///|
pub fn PromptBuilder::add_user(
  self : PromptBuilder,
  content : String,
) -> PromptBuilder {
  self.entries.push(PromptEntry::new(PromptRole::User, content))
  self
}

///|
pub fn PromptBuilder::add_assistant(
  self : PromptBuilder,
  content : String,
) -> PromptBuilder {
  self.entries.push(PromptEntry::new(PromptRole::Assistant, content))
  self
}

///|
pub fn PromptBuilder::add_tool(
  self : PromptBuilder,
  content : String,
) -> PromptBuilder {
  self.entries.push(PromptEntry::new(PromptRole::Tool, content))
  self
}

///|
/// Build the final message array.
pub fn PromptBuilder::build(
  self : PromptBuilder,
) -> Array[@llm.ChatMessage] {
  let messages : Array[@llm.ChatMessage] = []
  let system = resolve_template(self.system_prompt, self.vars)
  messages.push(@llm.ChatMessage::new(@llm.ChatRole::system(), system))
  for entry in self.entries {
    let content = resolve_template(entry.content, self.vars)
    let role = prompt_role_to_chat(entry.role)
    messages.push(@llm.ChatMessage::new(role, content))
  }
  messages
}

///|
fn resolve_template(template : String, vars : Map[String, String]) -> String {
  let mut result = template
  for k, v in vars {
    result = result.replace(old="{" + k + "}", new=v)
  }
  result
}

///|
fn prompt_role_to_chat(role : PromptRole) -> @llm.ChatRole {
  match role {
    PromptRole::System => @llm.ChatRole::system()
    PromptRole::User => @llm.ChatRole::user()
    PromptRole::Assistant => @llm.ChatRole::assistant()
    PromptRole::Tool => @llm.ChatRole::tool()
  }
}
