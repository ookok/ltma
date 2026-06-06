///|
/// SQLite-backed session manager.

///|
pub struct SessionStore {
  conn : @sqlite3.Connection
}

///|
pub fn SessionStore::open(path : String) -> SessionStore raise @sqlite3.SqliteError {
  let conn = @sqlite3.Connection::open(path)
  let stmt = conn.prepare(
    #|CREATE TABLE IF NOT EXISTS sessions (
    #|  session_id TEXT NOT NULL,
    #|  msg_index  INT  NOT NULL,
    #|  role       TEXT NOT NULL,
    #|  content    TEXT NOT NULL,
    #|  PRIMARY KEY (session_id, msg_index)
    #|);
  )
  stmt.step_once()
  stmt.finalize()
  { conn }
}

///|
pub fn SessionStore::add_message(
  self : SessionStore,
  session_id : String,
  role : String,
  content : String,
) -> Unit raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    #|INSERT INTO sessions (session_id, msg_index, role, content)
    #|VALUES (?, (SELECT COALESCE(MAX(msg_index), -1) + 1 FROM sessions WHERE session_id = ?), ?, ?)
  )
  stmt.bind_string_as_blob(index=1, val=session_id)
  stmt.bind_string_as_blob(index=2, val=session_id)
  stmt.bind_string_as_blob(index=3, val=role)
  stmt.bind_string_as_blob(index=4, val=content)
  stmt.step_once()
  stmt.finalize()
}

///|
pub fn SessionStore::get_history(
  self : SessionStore,
  session_id : String,
) -> Array[String] raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    #|SELECT content FROM sessions
    #|WHERE session_id = ? ORDER BY msg_index
  )
  stmt.bind_string_as_blob(index=1, val=session_id)
  let result : Array[String] = []
  while stmt.step() {
    result.push(stmt.column_blob_as_string(index=0))
  }
  stmt.finalize()
  result
}

///|
pub fn SessionStore::list_sessions(
  self : SessionStore,
) -> Array[String] raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    #|SELECT DISTINCT session_id FROM sessions ORDER BY session_id
  )
  let result : Array[String] = []
  while stmt.step() {
    result.push(stmt.column_blob_as_string(index=0))
  }
  stmt.finalize()
  result
}

///|
pub fn SessionStore::clear(
  self : SessionStore,
  session_id : String,
) -> Unit raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    #|DELETE FROM sessions WHERE session_id = ?
  )
  stmt.bind_string_as_blob(index=1, val=session_id)
  stmt.step_once()
  stmt.finalize()
}

///|
pub fn SessionStore::close(self : SessionStore) -> Unit raise @sqlite3.SqliteError {
  self.conn.close()
}
