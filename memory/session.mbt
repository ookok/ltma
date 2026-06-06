///|
/// Session manager — persists conversations across turns.

///|
pub struct SessionManager {
  sessions : Map[String, Array[String]]
}

///|
pub fn SessionManager::new() -> SessionManager {
  { sessions: Map([]) }
}

///|
pub fn SessionManager::get_or_create(
  self : SessionManager,
  session_id : String,
) -> Array[String] {
  match self.sessions.get(session_id) {
    Some(msgs) => msgs
    None => {
      let msgs : Array[String] = []
      self.sessions[session_id] = msgs
      msgs
    }
  }
}

///|
pub fn SessionManager::add_message(
  self : SessionManager,
  session_id : String,
  content : String,
) -> Unit {
  let msgs = self.get_or_create(session_id)
  msgs.push(content)
}

///|
pub fn SessionManager::get_history(
  self : SessionManager,
  session_id : String,
) -> Array[String] {
  self.get_or_create(session_id)
}

///|
pub fn SessionManager::clear(
  self : SessionManager,
  session_id : String,
) -> Unit {
  self.sessions.remove(session_id)
}

///|
pub fn SessionManager::list_sessions(self : SessionManager) -> Array[String] {
  let keys : Array[String] = []
  for k, _ in self.sessions {
    keys.push(k)
  }
  keys
}
