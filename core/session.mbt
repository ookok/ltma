///|
/// Session management — conversation context and state persistence.

///|
/// SessionId — unique session identifier.
pub struct SessionId {
  value : String
}

///|
pub fn SessionId::new(value : String) -> SessionId {
  { value, }
}

///|
pub fn SessionId::to_string(self : SessionId) -> String {
  self.value
}

///|
/// SessionState — persisted state for a session.
pub struct SessionState {
  id : SessionId
  messages : Array[Message]
  metadata : Map[String, String]
  created_at : Int
  mut updated_at : Int
}

///|
pub fn SessionState::new(id : SessionId) -> SessionState {
  { id, messages: [], metadata: Map([]), created_at: 0, updated_at: 0 }
}

///|
pub fn SessionState::add_message(self : SessionState, msg : Message) -> Unit {
  self.messages.push(msg)
  self.updated_at = 0
}

///|
pub fn SessionState::set_meta(
  self : SessionState,
  key : String,
  value : String,
) -> Unit {
  self.metadata[key] = value
}

///|
pub fn SessionState::get_meta(self : SessionState, key : String) -> String? {
  self.metadata.get(key)
}

///|
/// SessionStore — in-memory session storage with optional persistence.
pub struct SessionStore {
  sessions : Map[String, SessionState]
}

///|
pub fn SessionStore::new() -> SessionStore {
  { sessions: Map([]) }
}

///|
pub fn SessionStore::create(
  self : SessionStore,
  id : SessionId,
) -> SessionState {
  let state = SessionState::new(id)
  self.sessions[id.to_string()] = state
  state
}

///|
pub fn SessionStore::get(self : SessionStore, id : SessionId) -> SessionState? {
  self.sessions.get(id.to_string())
}

///|
pub fn SessionStore::remove(self : SessionStore, id : SessionId) -> Unit {
  self.sessions.remove(id.to_string())
}

///|
pub fn SessionStore::list(self : SessionStore) -> Array[SessionState] {
  let result : Array[SessionState] = []
  for _, s in self.sessions {
    result.push(s)
  }
  result
}

///|
pub fn SessionStore::count(self : SessionStore) -> Int {
  self.sessions.length()
}
