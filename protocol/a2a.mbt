///|
/// A2A — Agent-to-Agent protocol handler.

///|
/// A2ARouter — routes A2A messages between agents.
pub struct A2ARouter {
  handlers : Map[String, A2AEventHandler]
}

///|
pub type A2AEventHandler = (A2AMessage) -> A2AMessage?

///|
pub fn A2ARouter::new() -> A2ARouter {
  { handlers: Map([]) }
}

///|
pub fn A2ARouter::register(
  self : A2ARouter,
  agent_name : String,
  handler : A2AEventHandler,
) -> Unit {
  self.handlers[agent_name] = handler
}

///|
pub fn A2ARouter::unregister(self : A2ARouter, agent_name : String) -> Unit {
  self.handlers.remove(agent_name)
}

///|
/// Send a message to a specific agent. Returns the response, if any.
pub fn A2ARouter::send(self : A2ARouter, msg : A2AMessage) -> A2AMessage? {
  match self.handlers.get(msg.to_agent) {
    Some(handler) => handler(msg)
    None => None
  }
}

///|
/// Broadcast a message to all registered agents. Returns all responses.
pub fn A2ARouter::broadcast(
  self : A2ARouter,
  msg : A2AMessage,
) -> Array[A2AMessage] {
  let results : Array[A2AMessage] = []
  for agent_name, handler in self.handlers {
    let broadcast_msg = A2AMessage::create(
      msg.id,
      msg.from_agent,
      agent_name,
      msg.kind(),
      msg.payload,
      msg.correlation_id,
      msg.timestamp,
    )
    match handler(broadcast_msg) {
      Some(resp) => results.push(resp)
      None => ()
    }
  }
  results
}

///|
/// Create a simple echo handler for testing.
pub fn create_echo_handler() -> A2AEventHandler {
  fn(msg : A2AMessage) -> A2AMessage? {
    Some(
      A2AMessage::create(
        "echo-\{msg.id}",
        msg.to_agent,
        msg.from_agent,
        A2AMessageKind::Response,
        "echo: \{msg.payload}",
        Some(msg.id),
        0L,
      ),
    )
  }
}

///|
/// Perform a handoff: send a HandoffRequest as an A2AMessage to the target agent.
pub fn perform_handoff(
  router : A2ARouter,
  req : HandoffRequest,
) -> HandoffResponse? {
  let payload = encode_handoff_request(req)
  let msg = A2AMessage::create(
    "handoff-1",
    req.from_agent,
    req.to_agent,
    A2AMessageKind::Handoff,
    payload,
    None,
    0L,
  )
  match router.send(msg) {
    Some(resp) =>
      if resp.payload != "" {
        Some(HandoffResponse::new(true, Some(resp.payload), None))
      } else {
        None
      }
    None => Some(HandoffResponse::new(false, None, Some("agent not found")))
  }
}
