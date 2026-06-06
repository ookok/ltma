///|
fn make_echo_handle() -> @core.AgentHandle {
  let meta = @core.AgentMetadata::create(
    @core.AgentId::create("echo", "0.1.0", "test"),
    "echo",
    ["echo"],
    @core.IsolationLevel::in_process(),
    @core.Target::native(),
    "0.1.0",
  )
  @core.make_handle(
    (),
    fn(_) { "echo" },
    fn(_) { meta },
    fn(_, _) {  },
    fn(_, input) {
      if input.is_text() {
        @core.Message::text("echo: " + input.get_text())
      } else {
        @core.Message::text("unhandled")
      }
    },
    fn(_) {  },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, call) { @core.ToolResult::create(call.id, false, "", None) },
  )
}

///|
test "AgentAdapter delegate to handle" {
  let handle = make_echo_handle()
  let adapter = AgentAdapter::new(handle)
  let ctx = @core.AgentContext::new(
    @core.AgentId::create("echo", "0.1.0", "test"),
  )
  adapter.initialize(ctx)
  let resp = adapter.call(@core.Message::text("hello"))
  assert_true(resp.is_text())
  adapter.shutdown()
}

///|
test "AgentAdapter status tracking" {
  let handle = make_echo_handle()
  let adapter = AgentAdapter::new(handle)
  let ctx = @core.AgentContext::new(
    @core.AgentId::create("echo", "0.1.0", "test"),
  )
  adapter.initialize(ctx)
  let resp = adapter.call(@core.Message::text("ping"))
  assert_true(resp.is_text())
  assert_true(adapter.status().is_idle())
  adapter.shutdown()
  assert_true(adapter.status().is_shutdown())
}

///|
test "serialize_message produces JSON" {
  let msg = @core.Message::text("hello")
  let data = serialize_message(msg)
  assert_true(data.contains("\"kind\":\"text\""))
  assert_true(data.contains("hello"))
}

///|
test "deserialize_message round-trip" {
  let msg = @core.Message::text("hello world")
  let data = serialize_message(msg)
  let decoded = deserialize_message(data)
  match decoded {
    Some(m) => assert_eq(m.get_text(), "hello world")
    None => assert_true(false)
  }
}

///|
test "Sandbox lifecycle" {
  let config = SandboxConfig::in_process()
  let sandbox = Sandbox::new(config)
  assert_false(sandbox.is_active())
  sandbox.start()
  assert_true(sandbox.is_active())
  sandbox.stop()
  assert_false(sandbox.is_active())
}

///|
test "create_sandbox maps isolation level" {
  let ip = create_sandbox(@core.IsolationLevel::in_process())
  assert_true(ip.config().kind is SandboxKind::InProcess)
  let wasm = create_sandbox(@core.IsolationLevel::wasm_sandbox())
  assert_true(wasm.config().kind is SandboxKind::Wasm)
  let proc = create_sandbox(@core.IsolationLevel::process())
  assert_true(proc.config().kind is SandboxKind::Process)
}
