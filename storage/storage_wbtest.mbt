///|
test "KvStore set and get" {
  let store = KvStore::open(":memory:")
  store.set("k1", "v1")
  assert_eq(store.get("k1"), Some("v1"))
  assert_eq(store.get("nonexistent"), None)
}

///|
test "KvStore remove and clear" {
  let store = KvStore::open(":memory:")
  store.set("a", "1")
  store.set("b", "2")
  assert_eq(store.count(), 2)
  store.remove("a")
  assert_eq(store.count(), 1)
  store.clear()
  assert_eq(store.count(), 0)
}

///|
test "KvStore list" {
  let store = KvStore::open(":memory:")
  store.set("x", "10")
  store.set("y", "20")
  let keys = store.list()
  assert_eq(keys.length(), 2)
}

///|
test "SessionStore add and get history" {
  let ss = SessionStore::open(":memory:")
  ss.add_message("s1", "user", "hello")
  ss.add_message("s1", "assistant", "hi")
  ss.add_message("s2", "user", "ping")
  let h = ss.get_history("s1")
  assert_eq(h.length(), 2)
  let sessions = ss.list_sessions()
  assert_eq(sessions.length(), 2)
  ss.clear("s1")
  assert_eq(ss.get_history("s1").length(), 0)
}

///|
test "KnowledgeStore add and search entities" {
  let ks = KnowledgeStore::open(":memory:")
  ks.add_entity("e1", "MoonBit", "language", "A Rust-inspired language")
  ks.add_entity("e2", "LTMA", "framework", "AI Agent framework")
  // Search by exact entity_id to verify get_entity
  let e = ks.get_entity("e1")
  match e {
    Some((name, typ, meta)) => {
      assert_eq(name, "MoonBit")
      assert_eq(typ, "language")
    }
    None => assert_true(false)
  }
}

///|
test "KnowledgeStore add and query relations" {
  let ks = KnowledgeStore::open(":memory:")
  ks.add_entity("ltma", "LTMA", "framework", "desc")
  ks.add_entity("mb", "MoonBit", "lang", "desc")
  ks.add_relation("ltma", "built_with", "mb")
  let rels = ks.query_relations("ltma")
  assert_eq(rels.length(), 1)
  let (pred, obj) = rels[0]
  assert_eq(pred, "built_with")
  assert_eq(obj, "mb")
}
