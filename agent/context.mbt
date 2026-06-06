///|
/// Agent session — per-agent runtime state.

///|
pub struct AgentSession {
  agent_id : @core.AgentId
  mut session_id : String
  params : Map[String, String]
  variables : Map[String, String]
}

///|
pub fn AgentSession::new(agent_id : @core.AgentId) -> AgentSession {
  { agent_id, session_id: "", params: Map([]), variables: Map([]) }
}

///|
pub fn AgentSession::new_with_session(
  agent_id : @core.AgentId,
  session_id : String,
) -> AgentSession {
  { agent_id, session_id, params: Map([]), variables: Map([]) }
}

///|
pub fn AgentSession::set_session(
  self : AgentSession,
  session_id : String,
) -> Unit {
  self.session_id = session_id
}

///|
pub fn AgentSession::session(self : AgentSession) -> String {
  self.session_id
}

///|
pub fn AgentSession::set_param(
  self : AgentSession,
  key : String,
  value : String,
) -> Unit {
  self.params[key] = value
}

///|
pub fn AgentSession::get_param(self : AgentSession, key : String) -> String? {
  self.params.get(key)
}

///|
pub fn AgentSession::set_var(
  self : AgentSession,
  key : String,
  value : String,
) -> Unit {
  self.variables[key] = value
}

///|
pub fn AgentSession::get_var(self : AgentSession, key : String) -> String? {
  self.variables.get(key)
}
