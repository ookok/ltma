///|
/// OpenAI-compatible LLM API — async HTTP implementation.

///|
/// Escape a string for inclusion in JSON (escape backslash and quotes).
fn escape_json(s : String) -> String {
  let s1 = s.replace(old="\\", new="/")
  s1.replace(old="\"", new="'")
}

///|
/// Build the JSON body for an OpenAI-compatible chat completion request.
pub fn build_chat_body(
  config : LLMConfig,
  messages : Array[ChatMessage],
  tools : Array[ChatToolDef]?,
) -> String {
  let msgs_json = build_messages_json(messages)
  let tools_json = match tools {
    Some(t) => build_tools_json(t)
    None => ""
  }
  "{\"model\":\"" +
  config.model +
  "\",\"messages\":" +
  msgs_json +
  tools_json +
  ",\"max_tokens\":" +
  config.max_tokens.to_string() +
  ",\"temperature\":" +
  config.temperature.to_string() +
  "}"
}

///|
fn build_messages_json(messages : Array[ChatMessage]) -> String {
  let mut result = "["
  let mut first = true
  for i = 0; i < messages.length(); i = i + 1 {
    let msg = messages[i]
    if !first {
      result = result + ","
    }
    let role_str = role_to_string(msg.role)
    let content = escape_json(msg.content)
    result = result +
      "{\"role\":\"" +
      role_str +
      "\",\"content\":\"" +
      content +
      "\"}"
    first = false
  }
  result + "]"
}

///|
fn build_tools_json(tools : Array[ChatToolDef]) -> String {
  let mut result = ",\"tools\":["
  let mut first = true
  for i = 0; i < tools.length(); i = i + 1 {
    let t = tools[i]
    if !first {
      result = result + ","
    }
    let desc = escape_json(t.description)
    result = result +
      "{\"type\":\"function\",\"function\":{\"name\":\"" +
      t.name +
      "\",\"description\":\"" +
      desc +
      "\",\"parameters\":" +
      t.parameters +
      "}}"
    first = false
  }
  result + "]"
}

///|
fn role_to_string(role : ChatRole) -> String {
  if role.code == 0 {
    "system"
  } else if role.code == 1 {
    "user"
  } else if role.code == 2 {
    "assistant"
  } else {
    "tool"
  }
}

///|
/// Call an OpenAI-compatible chat completion API (async).
pub async fn call_openai_api(
  config : LLMConfig,
  messages : Array[ChatMessage],
  tools : Array[ChatToolDef]?,
) -> LLMResponse {
  let headers = Map([
    ("Content-Type", "application/json"),
    ("Authorization", "Bearer " + config.api_key),
  ])
  let body = build_chat_body(config, messages, tools)
  let (resp, data) = @async_http.post(config.api_url, body, headers~)
  if resp.code == 200 {
    parse_openai_response(data.text())
  } else {
    LLMResponse::{
      content: "API error: " + resp.code.to_string(),
      tool_calls: None,
      finish_reason: "error",
      usage: None,
    }
  }
}

///|
/// Parse an OpenAI-compatible response body into LLMResponse.
pub fn parse_openai_response(body : String) -> LLMResponse {
  let content = extract_quoted(body, "\"content\":\"")
  let finish = extract_quoted(body, "\"finish_reason\":\"")
  let calls = extract_tool_calls(body)
  let usage = extract_usage(body)
  LLMResponse::{
    content: content.unwrap_or(""),
    tool_calls: calls,
    finish_reason: finish.unwrap_or("stop"),
    usage,
  }
}

///|
/// Extract token usage from an OpenAI response body.
fn extract_usage(body : String) -> TokenUsage? {
  let prompt = extract_int_field(body, "\"prompt_tokens\"")
  let completion = extract_int_field(body, "\"completion_tokens\"")
  let total = extract_int_field(body, "\"total_tokens\"")
  match (prompt, completion, total) {
    (Some(p), Some(c), Some(t)) => Some({ prompt_tokens: p, completion_tokens: c, total_tokens: t })
    _ => None
  }
}

///|
fn extract_int_field(json : String, field : String) -> Int? {
  let search = field + ":"
  match json.find(search) {
    Some(start) => {
      let after = json.sub(start=start + search.length()).to_owned()
      let mut num_str = ""
      for i = 0; i < after.length(); i = i + 1 {
        let c = after[i]
        if c >= '0' && c <= '9' {
          num_str = num_str + c.to_string()
        } else {
          break
        }
      }
      if num_str != "" { Some(try { @string.parse_int(num_str) } catch { _ => 0 }) } else { None }
    }
    None => None
  }
}

///|
fn extract_quoted(json : String, prefix : String) -> String? {
  match json.find(prefix) {
    Some(start) => {
      let after = json.sub(start=start + prefix.length())
      match after.find("\"") {
        Some(end) => Some(after.sub(start=0, end~).to_owned())
        None => None
      }
    }
    None => None
  }
}

///|
/// Extract tool_calls array from an OpenAI response body.
fn extract_tool_calls(body : String) -> Array[ChatToolCall]? {
  if !body.contains("\"tool_calls\"") {
    return None
  }
  let calls : Array[ChatToolCall] = []
  let id_prefix = "\"id\":\""
  let name_prefix = "\"name\":\""
  let args_prefix = "\"arguments\":\""
  let mut pos = 0
  let mut running = true
  while running {
    let remaining = body.sub(start=pos)
    match remaining.find(id_prefix) {
      Some(offset) => {
        let chunk = remaining.sub(start=offset)
        let id = extract_quoted(chunk.to_owned(), id_prefix)
        let name = extract_quoted(chunk.to_owned(), name_prefix)
        let args = extract_quoted(chunk.to_owned(), args_prefix)
        calls.push(
          ChatToolCall::create(
            id.unwrap_or(""),
            name.unwrap_or(""),
            args.unwrap_or(""),
          ),
        )
        pos = pos + offset + 1
      }
      None => running = false
    }
  }
  if calls.length() > 0 {
    Some(calls)
  } else {
    None
  }
}

///|
/// Create an async provider handle for OpenAI-compatible API.
/// Makes real HTTP calls via the async runtime.
pub fn create_async_openai_provider(config : LLMConfig) -> AsyncLLMProviderHandle {
  AsyncLLMProviderHandle::{
    config_fn: fn() { config },
    chat_fn: async fn(messages, tools) {
      call_openai_api(config, messages, tools)
    },
  }
}

///|
/// Create a sync provider handle for OpenAI-compatible API (mock).
pub fn create_openai_provider(config : LLMConfig) -> LLMProviderHandle {
  LLMProviderHandle::{
    config_fn: fn() { config },
    chat_fn: fn(_messages, _tools) {
      LLMResponse::{
        content: "[openai provider: sync mode, use create_async_openai_provider for real calls]",
        tool_calls: None,
        finish_reason: "stop",
        usage: None,
      }
    },
  }
}
