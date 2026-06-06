///|
/// In-memory store — simple Map-based backend.

///|
pub struct InMemoryStore {
  mut entries : Map[String, MemoryEntry]
  mut counter : Int64
}

///|
pub fn InMemoryStore::new() -> InMemoryStore {
  { entries: Map([]), counter: 0L }
}

///|
pub fn InMemoryStore::store(
  self : InMemoryStore,
  key : String,
  value : String,
) -> Unit {
  self.counter = self.counter + 1L
  self.entries[key] = MemoryEntry::{ key, value, created_at: self.counter }
}

///|
pub fn InMemoryStore::retrieve(self : InMemoryStore, key : String) -> String? {
  match self.entries.get(key) {
    Some(e) => Some(e.value)
    None => None
  }
}

///|
pub fn InMemoryStore::remove(self : InMemoryStore, key : String) -> Unit {
  self.entries.remove(key)
}

///|
pub fn InMemoryStore::list(self : InMemoryStore) -> Array[MemoryEntry] {
  let result : Array[MemoryEntry] = []
  for _, v in self.entries {
    result.push(v)
  }
  result
}

///|
pub fn InMemoryStore::clear(self : InMemoryStore) -> Unit {
  self.entries = Map([])
}

///|
/// Create a MemoryStoreHandle from an InMemoryStore
pub fn create_memory_handle(store : InMemoryStore) -> MemoryStoreHandle {
  MemoryStoreHandle::{
    store_fn: fn(k, v) { store.store(k, v) },
    retrieve_fn: fn(k) { store.retrieve(k) },
    remove_fn: fn(k) { store.remove(k) },
    list_fn: fn() { store.list() },
    clear_fn: fn() { store.clear() },
  }
}
