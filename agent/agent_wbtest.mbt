///|
test "AgentSession session management" {
  let id = @core.AgentId::create("test", "1.0", "test-pkg")
  let ctx = AgentSession::new(id)
  assert_eq(ctx.session(), "")
  ctx.set_session("sess-1")
  assert_eq(ctx.session(), "sess-1")
}

///|
test "AgentSession params" {
  let id = @core.AgentId::create("test", "1.0", "test-pkg")
  let ctx = AgentSession::new(id)
  ctx.set_param("key1", "value1")
  let v = ctx.get_param("key1")
  assert_eq(v, Some("value1"))
  let missing = ctx.get_param("nonexistent")
  assert_eq(missing, None)
}

///|
test "AgentSession variables" {
  let id = @core.AgentId::create("test", "1.0", "test-pkg")
  let ctx = AgentSession::new(id)
  ctx.set_var("var1", "val1")
  assert_eq(ctx.get_var("var1"), Some("val1"))
}

///|
test "AgentRegistry register and resolve" {
  let reg = AgentRegistry::new()
  let meta = @core.AgentMetadata::create(
    @core.AgentId::create("test", "1.0", "test-pkg"),
    "test agent",
    ["test"],
    @core.IsolationLevel::in_process(),
    @core.Target::native(),
    "1.0",
  )
  let factory : () -> @core.AgentHandle = fn() {
    @core.make_handle(
      (),
      fn(_) { "test" },
      fn(_) { meta },
      fn(_, _) {  },
      fn(_, _) { @core.Message::text("ok") },
      fn(_) {  },
      fn(_) { @core.AgentStatus::idle() },
      fn(_, _) { @core.ToolResult::create("", false, "", None) },
    )
  }
  reg.register(meta, factory)
  assert_eq(reg.count(), 1)
  let resolved = reg.resolve(@core.AgentId::create("test", "1.0", "test-pkg"))
  assert_true(resolved is Some(_))
  reg.unregister(@core.AgentId::create("test", "1.0", "test-pkg"))
  assert_eq(reg.count(), 0)
}

///|
test "AgentRegistry list" {
  let reg = AgentRegistry::new()
  let meta = @core.AgentMetadata::create(
    @core.AgentId::create("a", "1.0", "pkg"),
    "agent a",
    [],
    @core.IsolationLevel::in_process(),
    @core.Target::native(),
    "1.0",
  )
  reg.register(meta, fn() {
    @core.make_handle(
      (),
      fn(_) { "a" },
      fn(_) { meta },
      fn(_, _) {  },
      fn(_, _) { @core.Message::text("") },
      fn(_) {  },
      fn(_) { @core.AgentStatus::idle() },
      fn(_, _) { @core.ToolResult::create("", false, "", None) },
    )
  })
  let list = reg.list()
  assert_eq(list.length(), 1)
}

///|
test "LifecycleHooks fire and logging hook" {
  let hooks = LifecycleHooks::new()
  let mut fired = false
  hooks.add(fn(_event, _id) { fired = true })
  let id = @core.AgentId::create("test", "1.0", "pkg")
  hooks.fire(LifecycleEvent::BeforeInit, id)
  assert_true(fired)
}

///|
test "Logging hook does not crash" {
  let hook = create_logging_hook()
  let id = @core.AgentId::create("test", "1.0", "pkg")
  hook(LifecycleEvent::AfterInit, id)
  hook(LifecycleEvent::BeforeRun, id)
  hook(LifecycleEvent::OnError("test error"), id)
  assert_true(true)
}
