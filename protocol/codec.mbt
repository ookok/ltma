///|
/// Codec — JSON serialization for A2A messages.

///|
/// Serialize an A2AMessage to a JSON string.
pub fn encode_message(msg : A2AMessage) -> String {
  let corr = match msg.correlation_id {
    Some(id) => ",\"correlation_id\":\"\{id}\""
    None => ""
  }
  let kind_name = match msg.kind() {
    A2AMessageKind::Request => "request"
    A2AMessageKind::Response => "response"
    A2AMessageKind::Handoff => "handoff"
    A2AMessageKind::Broadcast => "broadcast"
  }
  "{\"protocol\":\"ltma-a2a\",\"version\":\"1.0\",\"id\":\"\{msg.id}\",\"from\":\"\{msg.from_agent}\",\"to\":\"\{msg.to_agent}\",\"kind\":\"\{kind_name}\",\"payload\":\"\{msg.payload}\"\{corr},\"timestamp\":\{msg.timestamp.to_string()}}"
}

///|
/// Extract a quoted string field value from JSON by field name.
/// Returns `None` if field not found.
fn extract_field(json : String, field : String) -> String? {
  let search = "\"" + field + "\":\""
  let parts = json.split(search)
  let mut count = 0
  for _p in parts {
    count = count + 1
  }
  if count < 2 {
    return None
  }
  // Get the part after the field name
  let mut found = false
  let mut value : String = ""
  for p in parts {
    if found {
      // Extract until closing quote
      let end_parts = p.split("\"")
      let mut end_count = 0
      for _ep in end_parts {
        end_count = end_count + 1
      }
      if end_count >= 1 {
        for ep in end_parts {
          value = ep.trim().to_owned()
          break
        }
        return Some(value)
      }
      return None
    }
    found = true
  }
  None
}

///|
/// Decode a JSON string to an A2AMessage.
pub fn decode_message(json : String) -> A2AMessage? {
  let id = extract_field(json, "id")
  let from = extract_field(json, "from")
  let to_agent = extract_field(json, "to")
  let kind_str = extract_field(json, "kind")
  let payload = extract_field(json, "payload")
  let corr = extract_field(json, "correlation_id")

  if id is None ||
    from is None ||
    to_agent is None ||
    kind_str is None ||
    payload is None {
    return None
  }

  let kind = match kind_str.unwrap_or("") {
    "request" => A2AMessageKind::Request
    "response" => A2AMessageKind::Response
    "handoff" => A2AMessageKind::Handoff
    _ => A2AMessageKind::Broadcast
  }

  Some(
    A2AMessage::create(
      id.unwrap_or(""),
      from.unwrap_or(""),
      to_agent.unwrap_or(""),
      kind,
      payload.unwrap_or(""),
      corr,
      0L,
    ),
  )
}

///|
/// Encode a HandoffRequest to JSON.
pub fn encode_handoff_request(req : HandoffRequest) -> String {
  "{\"from_agent\":\"\{req.from_agent}\",\"to_agent\":\"\{req.to_agent}\",\"task\":\"\{req.task}\"}"
}

///|
/// Encode a HandoffResponse to JSON.
pub fn encode_handoff_response(resp : HandoffResponse) -> String {
  let result_field = match resp.result {
    Some(r) => ",\"result\":\"\{r}\""
    None => ""
  }
  let error_field = match resp.error {
    Some(e) => ",\"error\":\"\{e}\""
    None => ""
  }
  "{\"accepted\":\{resp.accepted.to_string()}\{result_field}\{error_field}}"
}
