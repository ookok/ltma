///|
/// Cache — LLM response caching with semantic and exact-match support.

///|
/// CacheEntry — a cached response with metadata.
pub struct CacheEntry {
  request_hash : String
  response : String
  created_at : Int
  ttl_ms : Int
  mut hit_count : Int
}

///|
pub fn CacheEntry::new(
  request_hash : String,
  response : String,
  ttl_ms : Int,
) -> CacheEntry {
  { request_hash, response, created_at: 0, ttl_ms, hit_count: 0 }
}

///|
pub fn CacheEntry::is_expired(self : CacheEntry) -> Bool {
  self.ttl_ms > 0 && 0 - self.created_at > self.ttl_ms
}

///|
/// ResponseCache — in-memory LRU-like cache for LLM responses.
pub struct ResponseCache {
  entries : Map[String, CacheEntry]
  max_size : Int
}

///|
pub fn ResponseCache::new(max_size : Int) -> ResponseCache {
  { entries: Map([]), max_size }
}

///|
pub fn ResponseCache::get(self : ResponseCache, key : String) -> String? {
  match self.entries.get(key) {
    Some(entry) =>
      if entry.is_expired() {
        self.entries.remove(key)
        None
      } else {
        entry.hit_count = entry.hit_count + 1
        Some(entry.response)
      }
    None => None
  }
}

///|
pub fn ResponseCache::put(
  self : ResponseCache,
  key : String,
  response : String,
  ttl_ms : Int,
) -> Unit {
  if self.entries.length() >= self.max_size {
    self.evict_one()
  }
  self.entries[key] = CacheEntry::new(key, response, ttl_ms)
}

///|
pub fn ResponseCache::invalidate(self : ResponseCache, key : String) -> Unit {
  self.entries.remove(key)
}

///|
pub fn ResponseCache::clear(self : ResponseCache) -> Unit {
  for key, _ in self.entries {
    self.entries.remove(key)
  }
  // Reset via re-assignment not possible, so we removed all entries.
  // This leaves an empty map. Iterate-and-remove is fine.
  // Actually let's just create a new map:
  let keys : Array[String] = []
  for k, _ in self.entries {
    keys.push(k)
  }
  for k in keys {
    self.entries.remove(k)
  }
}

///|
pub fn ResponseCache::size(self : ResponseCache) -> Int {
  self.entries.length()
}

///|
fn ResponseCache::evict_one(self : ResponseCache) -> Unit {
  let mut lru_key : String? = None
  let mut lru_hits = 0
  for key, entry in self.entries {
    match lru_key {
      Some(_) =>
        if entry.hit_count < lru_hits {
          lru_key = Some(key)
          lru_hits = entry.hit_count
        }
      None => {
        lru_key = Some(key)
        lru_hits = entry.hit_count
      }
    }
  }
  match lru_key {
    Some(k) => self.entries.remove(k)
    None => ()
  }
}
