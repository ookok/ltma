///|
/// Memory store types — closure-based handles for key-value storage.

///|
/// Memory entry with timestamp
pub struct MemoryEntry {
  key : String
  value : String
  created_at : Int64
}

///|
/// MemoryStoreHandle — closures for CRUD operations
pub struct MemoryStoreHandle {
  store_fn : (String, String) -> Unit
  retrieve_fn : (String) -> String?
  remove_fn : (String) -> Unit
  list_fn : () -> Array[MemoryEntry]
  clear_fn : () -> Unit
}

///|
pub fn MemoryStoreHandle::store(
  self : MemoryStoreHandle,
  key : String,
  value : String,
) -> Unit {
  (self.store_fn)(key, value)
}

///|
pub fn MemoryStoreHandle::retrieve(
  self : MemoryStoreHandle,
  key : String,
) -> String? {
  (self.retrieve_fn)(key)
}

///|
pub fn MemoryStoreHandle::remove(
  self : MemoryStoreHandle,
  key : String,
) -> Unit {
  (self.remove_fn)(key)
}

///|
pub fn MemoryStoreHandle::list(self : MemoryStoreHandle) -> Array[MemoryEntry] {
  (self.list_fn)()
}

///|
pub fn MemoryStoreHandle::clear(self : MemoryStoreHandle) -> Unit {
  (self.clear_fn)()
}
