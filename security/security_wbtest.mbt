///|
test "PermissionManager allow by default" {
  let pm = PermissionManager::permissive()
  let result = pm.check_tool("any-agent", "shell")
  assert_true(result is Permission::Allow)
}

///|
test "PermissionManager deny by default" {
  let pm = PermissionManager::new()
  let result = pm.check_tool("unknown", "shell")
  assert_true(result is Permission::Deny)
}

///|
test "AgentPermission can allow and deny tools" {
  let ap = AgentPermission::new("test-agent")
  ap.allow_tool("read")
  ap.allow_tool("write")
  ap.deny_tool("shell")
  assert_true(ap.can_use_tool("read") is Permission::Allow)
  assert_true(ap.can_use_tool("shell") is Permission::Deny)
}

///|
test "AuditLog records events" {
  let log = AuditLog::new(100)
  log.log(AuditEvent::AgentCreated("agent-1"))
  log.log(AuditEvent::ToolExecuted("agent-1", "read"))
  assert_eq(log.count(), 2)
  let recent = log.recent(5)
  assert_eq(recent.length(), 2)
}

///|
test "AuditLog respects max_entries" {
  let log = AuditLog::new(3)
  for i = 0; i < 5; i = i + 1 {
    log.log(AuditEvent::AgentCreated("agent-" + i.to_string()))
  }
  assert_eq(log.count(), 3)
  log.clear()
  assert_eq(log.count(), 0)
}

///|
test "SecurityPolicy default has tool restrictions" {
  let policy = SecurityPolicy::default()
  let engine = PolicyEngine::new(policy)
  let result = engine.check_tool("shell")
  assert_true(result is PolicyAction::RequireApproval)
}

///|
test "SecurityPolicy blocks restricted agents" {
  let policy = SecurityPolicy::restrictive()
  let engine = PolicyEngine::new(policy)
  let result = engine.check_tool("read")
  assert_true(result is PolicyAction::RequireApproval)
  let size_ok = engine.check_message_size(100)
  assert_true(size_ok is PolicyAction::Allow)
  let size_big = engine.check_message_size(99999)
  assert_true(size_big is PolicyAction::Deny)
}

///|
test "SecurityPolicy permissive allows most actions" {
  let policy = SecurityPolicy::permissive()
  let engine = PolicyEngine::new(policy)
  let result = engine.check_tool("read")
  assert_true(result is PolicyAction::Allow)
  let size_ok = engine.check_message_size(999999)
  assert_true(size_ok is PolicyAction::Allow)
}
