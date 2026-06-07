///|
/// Streaming LLM response via SSE.

///|
pub type StreamCallback = (String) -> Unit

///|
fn parse_sse_delta(line : String) -> String? {
  if !line.has_prefix("data: ") {
    return None
  }
  let payload = line[6:].to_owned()
  if payload == "[DONE]" {
    return Some("")
  }
  let content_search = "\"content\":\""
  let finish_search = "\"finish_reason\":"
  match payload.find(content_search) {
    Some(start) => {
      let after = payload.sub(start=start + content_search.length())
      match after.find("\"") {
        Some(end) => Some(after.sub(start=0, end~).to_owned())
        None => None
      }
    }
    None => if payload.contains(finish_search) { Some("") } else { None }
  }
}

///|
pub async fn chat_stream(
  config : LLMConfig,
  messages : Array[ChatMessage],
  tools : Array[ChatToolDef]?,
  on_token : StreamCallback,
) -> String {
  let body = build_chat_body(config, messages, tools)
  let stream_body = if body.length() > 0 && body[body.length() - 1] == '}' {
    body[0:body.length() - 1].to_owned() + ",\"stream\":true}"
  } else {
    body
  }

  let headers = Map([
    ("Content-Type", "application/json"),
    ("Authorization", "Bearer " + config.api_key),
  ])

  let client = @async_http.post_stream(config.api_url, headers~)
  let body_bytes = @encoding/utf8.encode(stream_body)
  let _ = client..write(body_bytes).end_request()

  let mut full = ""
  let mut line_bytes : Array[Byte] = []
  let mut more = true
  while more {
    let buf = FixedArray::make(4096, b'\x00')
    let n = client.read(buf, max_len=4096)
    if n <= 0 {
      more = false
      break
    }
    let view = buf.view(start=0, end=n)
    for i = 0; i < n; i = i + 1 {
      let b = view[i]
      if b == 10 {
        let raw = bytes_to_string_inline(line_bytes)
        match parse_sse_delta(raw) {
          Some(tok) =>
            if tok != "" {
              full = full + tok
              on_token(tok)
            }
          None => ()
        }
        line_bytes = []
      } else {
        line_bytes.push(b)
      }
    }
  }
  client.close()
  full
}

///|
fn bytes_to_string_inline(bytes : Array[Byte]) -> String {
  if bytes.length() == 0 {
    return ""
  }
  let arr = FixedArray::make(bytes.length(), b'\x00')
  for i = 0; i < bytes.length(); i = i + 1 {
    arr[i] = bytes[i]
  }
  let bs : Bytes = arr.unsafe_reinterpret_as_bytes()
  @encoding/utf8.decode_lossy(bs)
}
