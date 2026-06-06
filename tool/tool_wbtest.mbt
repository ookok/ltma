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

///|
test "ToolSandbox blocks denied tools" {
  let reg = ToolRegistry::new()
  let def = @core.ToolDefinition::create("echo", "echo", "", false)
  reg.register(def, fn(i) { "echo: " + i })
  let sb = ToolSandbox::new(reg)
  sb.deny_tool("echo")
  let result = sb.execute("echo", "hello")
  assert_false(result.allowed)
  assert_true(result.blocked_reason is Some(_))
}

///|
test "ToolSandbox enforces call quota" {
  let reg = ToolRegistry::new()
  let def = @core.ToolDefinition::create("t", "t", "", false)
  reg.register(def, fn(i) { i })
  let sb = ToolSandbox::with_limits(reg, 2, 1000)
  assert_eq(sb.remaining(), 2)
  let _ = sb.execute("t", "1")
  assert_eq(sb.remaining(), 1)
  let _ = sb.execute("t", "2")
  let r3 = sb.execute("t", "3")
  assert_false(r3.allowed)
}

///|
test "ToolSandbox allow list restricts tools" {
  let reg = ToolRegistry::new()
  reg.register(@core.ToolDefinition::create("a", "", "", false), fn(_) { "" })
  reg.register(@core.ToolDefinition::create("b", "", "", false), fn(_) { "" })
  let sb = ToolSandbox::new(reg)
  sb.allow_tool("a")
  assert_true(sb.execute("a", "").allowed)
  assert_false(sb.execute("b", "").allowed)
}

///|
test "ToolSandbox tracks audit log" {
  let reg = ToolRegistry::new()
  reg.register(@core.ToolDefinition::create("x", "", "", false), fn(_) { "" })
  let sb = ToolSandbox::new(reg)
  let _ = sb.execute("x", "data1")
  let _ = sb.execute("x", "data2")
  assert_eq(sb.audit().length(), 2)
}
