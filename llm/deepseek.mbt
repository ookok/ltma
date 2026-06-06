///|
/// DeepSeek LLM Provider — async HTTP implementation.
/// Uses `async fn` (no `raise` needed — async implies raising).

///|
/// Call DeepSeek API with a list of messages. Returns the response text.
pub async fn call_deepseek_api(
  config : LLMConfig,
  messages : Array[ChatMessage],
) -> String {
  let url = "https://api.deepseek.com/chat/completions"
  let headers = Map([
    ("Content-Type", "application/json"),
    ("Authorization", "Bearer \{config.api_key}"),
  ])
  let body = build_json_body(config, messages)
  let (resp, data) = @async_http.post(url, body, headers~)
  if resp.code == 200 {
    data.text()
  } else {
    "DeepSeek API error: \{resp.code}"
  }
}

///|
fn build_json_body(config : LLMConfig, messages : Array[ChatMessage]) -> String {
  let msgs_json = build_messages_array(messages)
  "{\"model\":\"\{config.model}\",\"messages\":\{msgs_json},\"max_tokens\":\{config.max_tokens.to_string()},\"temperature\":\{config.temperature.to_string()}}"
}

///|
fn build_messages_array(messages : Array[ChatMessage]) -> String {
  let mut result = "["
  let mut first = true
  for i = 0; i < messages.length(); i = i + 1 {
    let msg = messages[i]
    if !first {
      result = result + ","
    }
    let role_str = if msg.role.code == 0 {
      "system"
    } else if msg.role.code == 1 {
      "user"
    } else if msg.role.code == 2 {
      "assistant"
    } else {
      "tool"
    }
    result = result +
      "{\"role\":\"\{role_str}\",\"content\":\"\{msg.content}\"}"
    first = false
  }
  result = result + "]"
  result
}

///|
/// Mock LLM Provider — for testing without external API calls.
pub fn create_mock_provider(resp_text : String) -> LLMProviderHandle {
  let config = LLMConfig::deepseek_default("sk-mock")
  LLMProviderHandle::{
    config_fn: fn() { config },
    chat_fn: fn(_messages, _tools) {
      LLMResponse::{
        content: resp_text,
        tool_calls: None,
        finish_reason: "stop",
        usage: None,
      }
    },
  }
}
