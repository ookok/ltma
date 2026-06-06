///|
/// Vector store backed by trkbt10/vcdb — HNSW/IVF ANN search.

///|
/// VcdbVectorStore wraps trkbt10/vcdb for high-performance vector search.
/// TODO: full integration when vcdb API is stable.
pub struct VcdbVectorStore {
  dims : Int
}

///|
pub fn VcdbVectorStore::new(dims : Int) -> VcdbVectorStore {
  { dims }
}

///|
pub fn VcdbVectorStore::count(self : VcdbVectorStore) -> Int {
  0
}
