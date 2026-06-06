///|
/// Vector Store — in-memory vector DB with cosine similarity search.
fn sqrt_f64(x : Double) -> Double {
  if x <= 0.0 {
    0.0
  } else {
    let mut guess = x
    for _i = 0; _i < 20; _i = _i + 1 {
      guess = (guess + x / guess) / 2.0
    }
    guess
  }
}

///|
fn dot_product(a : Array[Double], b : Array[Double]) -> Double {
  let mut sum = 0.0
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i = 0; i < n; i = i + 1 {
    sum = sum + a[i] * b[i]
  }
  sum
}

///|
fn magnitude(v : Array[Double]) -> Double {
  sqrt_f64(dot_product(v, v))
}

///|
fn cosine_similarity(a : Array[Double], b : Array[Double]) -> Double {
  let mag_a = magnitude(a)
  let mag_b = magnitude(b)
  if mag_a <= 0.0 || mag_b <= 0.0 {
    0.0
  } else {
    dot_product(a, b) / (mag_a * mag_b)
  }
}

///|
/// EmbeddingProviderHandle — closure-based embedding service.
pub struct EmbeddingProviderHandle {
  embed_fn : (String) -> Array[Double]
}

///|
pub fn EmbeddingProviderHandle::create(
  embed_fn : (String) -> Array[Double],
) -> EmbeddingProviderHandle {
  { embed_fn, }
}

///|
pub fn EmbeddingProviderHandle::embed(
  self : EmbeddingProviderHandle,
  text : String,
) -> Array[Double] {
  (self.embed_fn)(text)
}

///|
pub struct VectorEntry {
  id : String
  text : String
  embedding : Array[Double]
  metadata : Map[String, String]
}

///|
pub fn VectorEntry::new(
  id : String,
  text : String,
  embedding : Array[Double],
  metadata : Map[String, String],
) -> VectorEntry {
  { id, text, embedding, metadata }
}

///|
pub struct VectorSearchResult {
  id : String
  score : Double
  text : String
  metadata : Map[String, String]
}

///|
pub fn VectorSearchResult::new(
  id : String,
  score : Double,
  text : String,
  metadata : Map[String, String],
) -> VectorSearchResult {
  { id, score, text, metadata }
}

///|
/// In-memory vector store with cosine similarity search.
pub struct VectorStore {
  mut entries : Map[String, VectorEntry]
  dims : Int
}

///|
pub fn VectorStore::new(dims : Int) -> VectorStore {
  { entries: Map([]), dims }
}

///|
pub fn VectorStore::add(self : VectorStore, entry : VectorEntry) -> Unit {
  self.entries[entry.id] = entry
}

///|
pub fn VectorStore::add_text(
  self : VectorStore,
  id : String,
  text : String,
  metadata : Map[String, String],
  provider : EmbeddingProviderHandle,
) -> Unit {
  let embedding = provider.embed(text)
  self.entries[id] = VectorEntry::new(id, text, embedding, metadata)
}

///|
pub fn VectorStore::get(self : VectorStore, id : String) -> VectorEntry? {
  self.entries.get(id)
}

///|
pub fn VectorStore::remove(self : VectorStore, id : String) -> Unit {
  self.entries.remove(id)
}

///|
pub fn VectorStore::count(self : VectorStore) -> Int {
  self.entries.length()
}

///|
pub fn VectorStore::clear(self : VectorStore) -> Unit {
  self.entries = Map([])
}

///|
pub fn VectorStore::search(
  self : VectorStore,
  query : String,
  top_k : Int,
  provider : EmbeddingProviderHandle,
) -> Array[VectorSearchResult] {
  let query_emb = provider.embed(query)
  let ids : Array[String] = []
  let scores : Array[Double] = []

  for id, entry in self.entries {
    let sim = cosine_similarity(query_emb, entry.embedding)
    ids.push(id)
    scores.push(sim)
  }

  // Simple selection sort (descending)
  let n = ids.length()
  for i = 0; i < n; i = i + 1 {
    let mut best_idx = i
    for j = i + 1; j < n; j = j + 1 {
      if scores[j] > scores[best_idx] {
        best_idx = j
      }
    }
    let tmp_id = ids[i]
    let tmp_score = scores[i]
    ids[i] = ids[best_idx]
    scores[i] = scores[best_idx]
    ids[best_idx] = tmp_id
    scores[best_idx] = tmp_score
  }

  let k = if top_k < n { top_k } else { n }
  let results : Array[VectorSearchResult] = []
  for i = 0; i < k; i = i + 1 {
    match self.entries.get(ids[i]) {
      Some(e) =>
        results.push(
          VectorSearchResult::new(e.id, scores[i], e.text, e.metadata),
        )
      None => ()
    }
  }
  results
}

///|
/// Create a mock embedding provider for testing.
pub fn create_mock_embedding_provider(dims : Int) -> EmbeddingProviderHandle {
  EmbeddingProviderHandle::{
    embed_fn: fn(text) {
      let result : Array[Double] = []
      let seed = text.length() * 31
      for i = 0; i < dims; i = i + 1 {
        let v = (seed * (i + 1) * 7 + 13) % 1000
        result.push(Double::from_int(v) / 1000.0)
      }
      result
    },
  }
}
