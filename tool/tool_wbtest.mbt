///|
/// Tests for ToolRegistry.
test "ToolRegistry register and resolve" {
  let reg = ToolRegistry::new()
  let def = @core.ToolDefinition::create("test-tool", "Test tool", "", false)
  reg.register(def, fn(input) { "processed: \{input}" })
  assert_eq(reg.count(), 1)
  match reg.resolve("test-tool") {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
  match reg.execute("test-tool", "data") {
    Some(v) => assert_eq(v, "processed: data")
    None => assert_true(false)
  }
}

///|
test "ToolRegistry unknown tool returns None" {
  let reg = ToolRegistry::new()
  match reg.execute("nonexistent", "data") {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}
