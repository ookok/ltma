///|
/// SQLite-backed key-value store.

///|
pub struct KvStore {
  conn : @sqlite3.Connection
}

///|
pub fn KvStore::open(path : String) -> KvStore raise @sqlite3.SqliteError {
  let conn = @sqlite3.Connection::open(path)
  let stmt = conn.prepare(
    (
      #|CREATE TABLE IF NOT EXISTS kv_store (
      #|  key   TEXT PRIMARY KEY NOT NULL,
      #|  value TEXT NOT NULL
      #|);
    ),
  )
  stmt.step_once()
  stmt.finalize()
  { conn, }
}

///|
pub fn KvStore::set(
  self : KvStore,
  key : String,
  value : String,
) -> Unit raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    (
      #|INSERT OR REPLACE INTO kv_store (key, value) VALUES (?, ?)
    ),
  )
  stmt.bind_string_as_blob(index=1, val=key)
  stmt.bind_string_as_blob(index=2, val=value)
  stmt.step_once()
  stmt.finalize()
}

///|
pub fn KvStore::get(
  self : KvStore,
  key : String,
) -> String? raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    (
      #|SELECT value FROM kv_store WHERE key = ?
    ),
  )
  stmt.bind_string_as_blob(index=1, val=key)
  let result = if stmt.step() {
    Some(stmt.column_blob_as_string(index=0))
  } else {
    None
  }
  stmt.finalize()
  result
}

///|
pub fn KvStore::remove(
  self : KvStore,
  key : String,
) -> Unit raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    (
      #|DELETE FROM kv_store WHERE key = ?
    ),
  )
  stmt.bind_string_as_blob(index=1, val=key)
  stmt.step_once()
  stmt.finalize()
}

///|
pub fn KvStore::list(
  self : KvStore,
) -> Array[String] raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    (
      #|SELECT key FROM kv_store ORDER BY key
    ),
  )
  let result : Array[String] = []
  while stmt.step() {
    result.push(stmt.column_blob_as_string(index=0))
  }
  stmt.finalize()
  result
}

///|
pub fn KvStore::count(self : KvStore) -> Int raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    (
      #|SELECT COUNT(*) FROM kv_store
    ),
  )
  let result = if stmt.step() {
    let c : Int = stmt.column(index=0)
    c
  } else {
    0
  }
  stmt.finalize()
  result
}

///|
pub fn KvStore::clear(self : KvStore) -> Unit raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare("DELETE FROM kv_store")
  stmt.step_once()
  stmt.finalize()
}

///|
pub fn KvStore::close(self : KvStore) -> Unit raise @sqlite3.SqliteError {
  self.conn.close()
}
