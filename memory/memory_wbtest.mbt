///|
/// Tests for memory package.
test "InMemoryStore store and retrieve" {
  let store = InMemoryStore::new()
  store.store("key1", "value1")
  store.store("key2", "value2")
  assert_eq(store.retrieve("key1"), Some("value1"))
  assert_eq(store.retrieve("key2"), Some("value2"))
  assert_eq(store.retrieve("nonexistent"), None)
}

///|
test "InMemoryStore remove and clear" {
  let store = InMemoryStore::new()
  store.store("a", "1")
  store.store("b", "2")
  assert_eq(store.list().length(), 2)
  store.remove("a")
  assert_eq(store.list().length(), 1)
  store.clear()
  assert_eq(store.list().length(), 0)
}

///|
test "SessionManager add and get" {
  let sm = SessionManager::new()
  sm.add_message("s1", "hello")
  sm.add_message("s1", "world")
  sm.add_message("s2", "foo")
  let h1 = sm.get_history("s1")
  assert_eq(h1.length(), 2)
  let h2 = sm.get_history("s2")
  assert_eq(h2.length(), 1)
  let sessions = sm.list_sessions()
  assert_eq(sessions.length(), 2)
}

///|
test "SessionManager clear" {
  let sm = SessionManager::new()
  sm.add_message("s1", "test")
  sm.clear("s1")
  assert_eq(sm.get_history("s1").length(), 0)
}

///|
test "ContextCompactor no compaction needed" {
  let cc = ContextCompactor::new(5)
  let msgs = ["a", "b", "c"]
  let result = cc.compact(msgs)
  assert_eq(result.length(), 3)
}

///|
test "ContextCompactor compacts when over limit" {
  let cc = ContextCompactor::new(3)
  let msgs = ["a", "b", "c", "d", "e"]
  let result = cc.compact(msgs)
  assert_eq(result.length(), 3)
  assert_true(result[0].has_prefix("[..."))
}

///|
test "MemoryStoreHandle creation" {
  let store = InMemoryStore::new()
  let handle = create_memory_handle(store)
  handle.store("k", "v")
  assert_eq(handle.retrieve("k"), Some("v"))
  handle.remove("k")
  assert_eq(handle.retrieve("k"), None)
}

///|
test "KnowledgeGraph add and query entities" {
  let kg = KnowledgeGraph::new()
  kg.add_entity(
    Entity::new("e1", "MoonBit", "language", "A Rust-inspired language"),
  )
  kg.add_entity(Entity::new("e2", "DeepSeek", "model", "An LLM by DeepSeek"))
  assert_eq(kg.count(), (2, 0))
  let e = kg.get_entity("e1")
  assert_true(e is Some(_))
  let results = kg.search_entities("deepseek")
  assert_eq(results.length(), 1)
}

///|
test "KnowledgeGraph relations" {
  let kg = KnowledgeGraph::new()
  kg.add_entity(Entity::new("ltma", "LTMA", "framework", "Agent framework"))
  kg.add_entity(
    Entity::new("moonbit", "MoonBit", "language", "Programming language"),
  )
  kg.add_relation(Relation::new("ltma", "built_with", "moonbit"))
  let rels = kg.query_relations("ltma")
  assert_eq(rels.length(), 1)
  assert_eq(rels[0].predicate, "built_with")
}

///|
test "KeywordIndex add and search" {
  let ki = KeywordIndex::new()
  ki.add_document(
    Document::new(
      "d1", "MoonBit Agent", "A framework for building AI agents in MoonBit",
    ),
  )
  ki.add_document(
    Document::new(
      "d2", "DeepSeek API", "API for calling DeepSeek large language models",
    ),
  )
  assert_eq(ki.count(), 2)
  let results = ki.search("moonbit agent")
  assert_true(results.length() >= 1)
}

///|
test "KeywordIndex no match" {
  let ki = KeywordIndex::new()
  ki.add_document(Document::new("d1", "Hello", "World"))
  let results = ki.search("nonexistent")
  assert_eq(results.length(), 0)
}

///|
test "VectorStore add and count" {
  let provider = create_mock_embedding_provider(4)
  let vs = VectorStore::new(4)
  vs.add_text("d1", "MoonBit programming language", Map([]), provider)
  vs.add_text("d2", "DeepSeek large language model", Map([]), provider)
  assert_eq(vs.count(), 2)
}

///|
test "VectorStore search returns results" {
  let provider = create_mock_embedding_provider(4)
  let vs = VectorStore::new(4)
  vs.add_text("d1", "MoonBit is a Rust-inspired language", Map([]), provider)
  vs.add_text("d2", "DeepSeek provides AI models", Map([]), provider)
  vs.add_text("d3", "LTMA is an agent framework", Map([]), provider)
  let results = vs.search("MoonBit", 2, provider)
  assert_true(results.length() > 0)
}

///|
test "VectorStore remove and clear" {
  let provider = create_mock_embedding_provider(4)
  let vs = VectorStore::new(4)
  vs.add_text("d1", "test document", Map([]), provider)
  assert_eq(vs.count(), 1)
  vs.remove("d1")
  assert_eq(vs.count(), 0)
  vs.add_text("d2", "another doc", Map([]), provider)
  vs.clear()
  assert_eq(vs.count(), 0)
}
