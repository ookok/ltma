///|
/// Message serialization for transport across the contract boundary.

///|
/// MarshalKind — discriminator for serialized payloads.
pub enum MarshalKind {
  Text
  System
  ToolCall
  ToolResult
  Status
  Error
}

///|
/// MarshalContext — context for encoding/decoding across boundaries.
pub struct MarshalContext {
  protocol_version : String
  encoding : String
}

///|
pub fn MarshalContext::new() -> MarshalContext {
  { protocol_version: "1.0", encoding: "json" }
}

///|
pub fn serialize_message(msg : @core.Message) -> String {
  if msg.is_text() {
    "{\"kind\":\"text\",\"value\":\"" + msg.get_text() + "\"}"
  } else {
    "{\"kind\":\"system\"}"
  }
}

///|
pub fn deserialize_message(data : String) -> @core.Message? {
  if data.contains("\"kind\":\"text\"") {
    let prefix = "\"value\":\""
    match data.find(prefix) {
      Some(start) => {
        let after = data.sub(start=start + prefix.length())
        match after.find("\"") {
          Some(end) =>
            Some(@core.Message::text(after.sub(start=0, end~).to_owned()))
          None => None
        }
      }
      None => None
    }
  } else {
    None
  }
}

///|
/// Marshal a ToolCall to JSON string.
pub fn serialize_tool_call(call : @core.ToolCall) -> String {
  "{\"id\":\"" +
  call.id +
  "\",\"name\":\"" +
  call.name +
  "\",\"arguments\":" +
  call.arguments +
  "}"
}

///|
/// Marshal a ToolResult to JSON string.
pub fn serialize_tool_result(result : @core.ToolResult) -> String {
  "{\"id\":\"" +
  result.id +
  "\",\"success\":" +
  result.success.to_string() +
  ",\"output\":\"" +
  result.output +
  "\"}"
}

///|
/// Marshal an AgentStatus to JSON string.
pub fn serialize_status(st : @core.AgentStatus) -> String {
  "{\"code\":" + st.code.to_string() + "}"
}
