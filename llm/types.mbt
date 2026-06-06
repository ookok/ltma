///|
/// LLM Provider types and handle (closures-based).

///|
pub struct LLMConfig {
  api_key : String
  model : String
  api_url : String
  max_tokens : Int
  temperature : Double
}

///|
pub fn LLMConfig::deepseek_default(api_key : String) -> LLMConfig {
  {
    api_key,
    model: "deepseek-v4-pro",
    api_url: "https://api.deepseek.com/chat/completions",
    max_tokens: 4096,
    temperature: 0.7,
  }
}

///|
/// OpenAI-compatible default config (also works for Anthropic, Azure, etc.)
pub fn LLMConfig::openai_default(api_key : String) -> LLMConfig {
  {
    api_key,
    model: "gpt-4o",
    api_url: "https://api.openai.com/v1/chat/completions",
    max_tokens: 4096,
    temperature: 0.7,
  }
}

///|
pub struct ChatRole {
  code : Int
}

///|
pub fn ChatRole::system() -> ChatRole {
  { code: 0 }
}

///|
pub fn ChatRole::user() -> ChatRole {
  { code: 1 }
}

///|
pub fn ChatRole::assistant() -> ChatRole {
  { code: 2 }
}

///|
pub fn ChatRole::tool() -> ChatRole {
  { code: 3 }
}

///|
pub struct ChatMessage {
  role : ChatRole
  content : String
}

///|
pub fn ChatMessage::new(role : ChatRole, content : String) -> ChatMessage {
  { role, content }
}

///|
pub struct ChatToolCall {
  id : String
  name : String
  arguments : String
}

///|
pub fn ChatToolCall::create(
  id : String,
  name : String,
  arguments : String,
) -> ChatToolCall {
  { id, name, arguments }
}

///|
pub struct ChatToolDef {
  name : String
  description : String
  parameters : String
  strict : Bool
}

///|
pub fn ChatToolDef::create(
  name : String,
  description : String,
  parameters : String,
  strict : Bool,
) -> ChatToolDef {
  { name, description, parameters, strict }
}

///|
pub struct LLMResponse {
  content : String
  tool_calls : Array[ChatToolCall]?
  finish_reason : String
}

///|
pub struct TokenUsage {
  prompt_tokens : Int
  completion_tokens : Int
  total_tokens : Int
}

///|
/// LLMProviderHandle — synchronous LLM provider (for testing, mock)
pub struct LLMProviderHandle {
  config_fn : () -> LLMConfig
  chat_fn : (Array[ChatMessage], Array[ChatToolDef]?) -> LLMResponse
}

///|
pub fn LLMProviderHandle::config(self : LLMProviderHandle) -> LLMConfig {
  (self.config_fn)()
}

///|
pub fn LLMProviderHandle::chat(
  self : LLMProviderHandle,
  messages : Array[ChatMessage],
  tools : Array[ChatToolDef]?,
) -> LLMResponse {
  (self.chat_fn)(messages, tools)
}

///|
/// AsyncLLMProviderHandle — async LLM provider (for real HTTP API calls)
pub struct AsyncLLMProviderHandle {
  config_fn : () -> LLMConfig
  chat_fn : async (Array[ChatMessage], Array[ChatToolDef]?) -> LLMResponse
}

///|
pub fn AsyncLLMProviderHandle::config(self : AsyncLLMProviderHandle) -> LLMConfig {
  (self.config_fn)()
}

///|
pub async fn AsyncLLMProviderHandle::chat(
  self : AsyncLLMProviderHandle,
  messages : Array[ChatMessage],
  tools : Array[ChatToolDef]?,
) -> LLMResponse {
  (self.chat_fn)(messages, tools)
}
