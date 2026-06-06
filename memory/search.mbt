///|
/// Keyword index — simple in-memory document search with relevance scoring.

///|
pub struct Document {
  id : String
  title : String
  content : String
}

///|
pub fn Document::new(id : String, title : String, content : String) -> Document {
  { id, title, content }
}

///|
pub struct KeywordIndex {
  docs : Map[String, Document]
  index : Map[String, Array[String]]
}

///|
pub fn KeywordIndex::new() -> KeywordIndex {
  { docs: Map([]), index: Map([]) }
}

///|
pub fn KeywordIndex::add_document(self : KeywordIndex, doc : Document) -> Unit {
  self.docs[doc.id] = doc
  let words = tokenize(doc.title + " " + doc.content)
  for w in words {
    let entries : Array[String] = match self.index.get(w) {
      Some(v) => v
      None => []
    }
    if !entries.contains(doc.id) {
      entries.push(doc.id)
    }
    self.index[w] = entries
  }
}

///|
pub fn KeywordIndex::search(
  self : KeywordIndex,
  query : String,
) -> Array[(String, Int, Document)] {
  let words = tokenize(query)
  if words.length() == 0 {
    return []
  }

  let scores : Map[String, Int] = Map([])
  for w in words {
    match self.index.get(w) {
      Some(doc_ids) =>
        for id in doc_ids {
          let current = scores.get(id).unwrap_or(0)
          scores[id] = current + 10
        }
      None => ()
    }
  }

  for w in words {
    for _, doc in self.docs {
      if doc.title.to_lower().contains(w) {
        let current = scores.get(doc.id).unwrap_or(0)
        scores[doc.id] = current + 5
      }
    }
  }

  let result : Array[(String, Int, Document)] = []
  for k, v in scores {
    match self.docs.get(k) {
      Some(doc) => result.push((k, v, doc))
      None => ()
    }
  }
  result
}

///|
pub fn KeywordIndex::count(self : KeywordIndex) -> Int {
  self.docs.length()
}

///|
fn tokenize(text : String) -> Array[String] {
  let lower = text.to_lower()
  let parts = lower.split(" ")
  let words : Array[String] = []
  for p in parts {
    let trimmed = p.trim()
    if trimmed != "" && trimmed.length() > 1 {
      words.push(trimmed.to_owned())
    }
  }
  words
}
