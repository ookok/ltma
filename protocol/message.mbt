///|
/// A2A message types — envelope and payload kinds.

///|
pub enum A2AMessageKind {
  Request
  Response
  Handoff
  Broadcast
}

///|
pub fn A2AMessageKind::request() -> A2AMessageKind {
  A2AMessageKind::Request
}

///|
pub fn A2AMessageKind::response() -> A2AMessageKind {
  A2AMessageKind::Response
}

///|
pub fn A2AMessageKind::handoff() -> A2AMessageKind {
  A2AMessageKind::Handoff
}

///|
pub fn A2AMessageKind::broadcast() -> A2AMessageKind {
  A2AMessageKind::Broadcast
}

///|
/// A2AMessage — the envelope for agent-to-agent communication.
pub struct A2AMessage {
  id : String
  from_agent : String
  to_agent : String
  kind_code : Int
  payload : String
  correlation_id : String?
  timestamp : Int64
}

///|
pub fn A2AMessage::create(
  id : String,
  from_agent : String,
  to_agent : String,
  kind : A2AMessageKind,
  payload : String,
  correlation_id : String?,
  timestamp : Int64,
) -> A2AMessage {
  let kind_code = match kind {
    A2AMessageKind::Request => 0
    A2AMessageKind::Response => 1
    A2AMessageKind::Handoff => 2
    A2AMessageKind::Broadcast => 3
  }
  { id, from_agent, to_agent, kind_code, payload, correlation_id, timestamp }
}

///|
pub fn A2AMessage::kind(self : A2AMessage) -> A2AMessageKind {
  if self.kind_code == 0 {
    A2AMessageKind::Request
  } else if self.kind_code == 1 {
    A2AMessageKind::Response
  } else if self.kind_code == 2 {
    A2AMessageKind::Handoff
  } else {
    A2AMessageKind::Broadcast
  }
}

///|
/// HandoffRequest — request to transfer a task to another agent.
pub struct HandoffRequest {
  from_agent : String
  to_agent : String
  task : String
  context_keys : Array[String]
  context_vals : Array[String]
}

///|
pub fn HandoffRequest::new(
  from_agent : String,
  to_agent : String,
  task : String,
  context : Map[String, String],
) -> HandoffRequest {
  let keys : Array[String] = []
  let vals : Array[String] = []
  for k, v in context {
    keys.push(k)
    vals.push(v)
  }
  { from_agent, to_agent, task, context_keys: keys, context_vals: vals }
}

///|
pub fn HandoffRequest::get_context(
  self : HandoffRequest,
) -> Map[String, String] {
  let m : Map[String, String] = Map([])
  let n = if self.context_keys.length() < self.context_vals.length() {
    self.context_keys.length()
  } else {
    self.context_vals.length()
  }
  for i = 0; i < n; i = i + 1 {
    m[self.context_keys[i]] = self.context_vals[i]
  }
  m
}

///|
/// HandoffResponse — result of a handoff request.
pub struct HandoffResponse {
  accepted : Bool
  result : String?
  error : String?
}

///|
pub fn HandoffResponse::new(
  accepted : Bool,
  result : String?,
  error : String?,
) -> HandoffResponse {
  { accepted, result, error }
}

///|
/// A2AProtocol — version identifier for protocol compatibility.
pub struct A2AProtocol {
  major : Int
  minor : Int
}

///|
pub fn A2AProtocol::current() -> A2AProtocol {
  { major: 1, minor: 0 }
}

///|
pub fn A2AProtocol::to_string(self : A2AProtocol) -> String {
  "\{self.major}.\{self.minor}"
}
