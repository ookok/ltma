///|
/// SQLite-backed knowledge graph.

///|
pub struct KnowledgeStore {
  conn : @sqlite3.Connection
}

///|
pub fn KnowledgeStore::open(path : String) -> KnowledgeStore raise @sqlite3.SqliteError {
  let conn = @sqlite3.Connection::open(path)
  let stmt = conn.prepare(
    #|CREATE TABLE IF NOT EXISTS entities (
    #|  entity_id   TEXT PRIMARY KEY NOT NULL,
    #|  name        TEXT NOT NULL,
    #|  entity_type TEXT NOT NULL,
    #|  metadata    TEXT NOT NULL
    #|);
  )
  stmt.step_once()
  stmt.finalize()

  let stmt2 = conn.prepare(
    #|CREATE TABLE IF NOT EXISTS relations (
    #|  subject   TEXT NOT NULL,
    #|  predicate TEXT NOT NULL,
    #|  object    TEXT NOT NULL,
    #|  PRIMARY KEY (subject, predicate, object)
    #|);
  )
  stmt2.step_once()
  stmt2.finalize()
  { conn }
}

///|
pub fn KnowledgeStore::add_entity(
  self : KnowledgeStore,
  entity_id : String,
  name : String,
  entity_type : String,
  metadata : String,
) -> Unit raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    #|INSERT OR REPLACE INTO entities (entity_id, name, entity_type, metadata)
    #|VALUES (?, ?, ?, ?)
  )
  stmt.bind_string_as_blob(index=1, val=entity_id)
  stmt.bind_string_as_blob(index=2, val=name)
  stmt.bind_string_as_blob(index=3, val=entity_type)
  stmt.bind_string_as_blob(index=4, val=metadata)
  stmt.step_once()
  stmt.finalize()
}

///|
pub fn KnowledgeStore::get_entity(
  self : KnowledgeStore,
  entity_id : String,
) -> (String, String, String)? raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    #|SELECT name, entity_type, metadata FROM entities WHERE entity_id = ?
  )
  stmt.bind_string_as_blob(index=1, val=entity_id)
  let result = if stmt.step() {
    Some((
      stmt.column_blob_as_string(index=0),
      stmt.column_blob_as_string(index=1),
      stmt.column_blob_as_string(index=2),
    ))
  } else {
    None
  }
  stmt.finalize()
  result
}

///|
pub fn KnowledgeStore::search_entities(
  self : KnowledgeStore,
  query : String,
) -> Array[(String, String, String, String)] raise @sqlite3.SqliteError {
  let like = "%" + query + "%"
  let stmt = self.conn.prepare(
    #|SELECT entity_id, name, entity_type, metadata FROM entities
    #|WHERE name LIKE ? OR entity_type LIKE ? OR metadata LIKE ?
    #|ORDER BY name
  )
  stmt.bind_string_as_blob(index=1, val=like)
  stmt.bind_string_as_blob(index=2, val=like)
  stmt.bind_string_as_blob(index=3, val=like)
  let result : Array[(String, String, String, String)] = []
  while stmt.step() {
    result.push((
      stmt.column_blob_as_string(index=0),
      stmt.column_blob_as_string(index=1),
      stmt.column_blob_as_string(index=2),
      stmt.column_blob_as_string(index=3),
    ))
  }
  stmt.finalize()
  result
}

///|
pub fn KnowledgeStore::add_relation(
  self : KnowledgeStore,
  subject : String,
  predicate : String,
  object : String,
) -> Unit raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    #|INSERT OR REPLACE INTO relations (subject, predicate, object)
    #|VALUES (?, ?, ?)
  )
  stmt.bind_string_as_blob(index=1, val=subject)
  stmt.bind_string_as_blob(index=2, val=predicate)
  stmt.bind_string_as_blob(index=3, val=object)
  stmt.step_once()
  stmt.finalize()
}

///|
pub fn KnowledgeStore::query_relations(
  self : KnowledgeStore,
  subject : String,
) -> Array[(String, String)] raise @sqlite3.SqliteError {
  let stmt = self.conn.prepare(
    #|SELECT predicate, object FROM relations WHERE subject = ?
  )
  stmt.bind_string_as_blob(index=1, val=subject)
  let result : Array[(String, String)] = []
  while stmt.step() {
    result.push((
      stmt.column_blob_as_string(index=0),
      stmt.column_blob_as_string(index=1),
    ))
  }
  stmt.finalize()
  result
}

///|
pub fn KnowledgeStore::close(self : KnowledgeStore) -> Unit raise @sqlite3.SqliteError {
  self.conn.close()
}
