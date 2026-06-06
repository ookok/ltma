///|
/// Tests for core types (whitebox — same package).
test "AgentId create and to_string" {
  let id = AgentId::create("test", "1.0.0", "livingtree/ltma")
  assert_eq(id.to_string(), "livingtree/ltma/test@1.0.0")
}

///|
test "AgentStatus lifecycle" {
  let s = AgentStatus::new_st()
  assert_true(s.is_new())
  let s2 = AgentStatus::idle()
  assert_true(s2.is_idle())
  let s3 = AgentStatus::shutdown_st()
  assert_true(s3.is_shutdown())
  let s4 = AgentStatus::error_st("something wrong")
  assert_true(s4.is_error())
}

///|
test "Message text roundtrip" {
  let msg = Message::text("hello world")
  assert_true(msg.is_text())
  assert_eq(msg.get_text(), "hello world")
}

///|
test "Message system requests" {
  let req = Message::system_status_request()
  assert_true(req.is_system_status_request())
  let shutdown = Message::system_shutdown()
  assert_true(shutdown.is_system_shutdown())
}

///|
test "IsolationLevel factory" {
  let ip = IsolationLevel::in_process()
  assert_eq(ip.code, 0)
  let ws = IsolationLevel::wasm_sandbox()
  assert_eq(ws.code, 1)
}

///|
test "Target factory" {
  let n = Target::native()
  assert_eq(n.code, 0)
}
