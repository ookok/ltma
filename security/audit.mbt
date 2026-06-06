///|
/// Audit logging for security events.

///|
pub enum AuditEvent {
  AgentCreated(String)
  AgentDestroyed(String)
  ToolExecuted(String, String)
  ToolDenied(String, String)
  MessageSent(String, String)
  PermissionCheck(String, String, Bool)
}

///|
fn audit_event_name(event : AuditEvent) -> String {
  match event {
    AuditEvent::AgentCreated(_) => "agent_created"
    AuditEvent::AgentDestroyed(_) => "agent_destroyed"
    AuditEvent::ToolExecuted(_, _) => "tool_executed"
    AuditEvent::ToolDenied(_, _) => "tool_denied"
    AuditEvent::MessageSent(_, _) => "message_sent"
    AuditEvent::PermissionCheck(_, _, _) => "permission_check"
  }
}

///|
pub struct AuditLog {
  mut entries : Array[String]
  max_entries : Int
}

///|
pub fn AuditLog::new(max_entries : Int) -> AuditLog {
  { entries: [], max_entries }
}

///|
pub fn AuditLog::log(self : AuditLog, event : AuditEvent) -> Unit {
  let line = format_event(event)
  self.entries.push(line)
  while self.entries.length() > self.max_entries {
    let _ = self.entries.remove(0)
  }
}

///|
pub fn AuditLog::recent(self : AuditLog, n : Int) -> Array[String] {
  let result : Array[String] = []
  let start_idx = self.entries.length() - n
  let i_start = if start_idx < 0 { 0 } else { start_idx }
  for i = i_start; i < self.entries.length(); i = i + 1 {
    result.push(self.entries[i])
  }
  result
}

///|
pub fn AuditLog::count(self : AuditLog) -> Int {
  self.entries.length()
}

///|
pub fn AuditLog::clear(self : AuditLog) -> Unit {
  self.entries = []
}

///|
fn format_event(event : AuditEvent) -> String {
  let name = audit_event_name(event)
  let detail = match event {
    AuditEvent::AgentCreated(id) => "agent=" + id
    AuditEvent::AgentDestroyed(id) => "agent=" + id
    AuditEvent::ToolExecuted(agent, tool) => "agent=" + agent + " tool=" + tool
    AuditEvent::ToolDenied(agent, tool) => "agent=" + agent + " tool=" + tool
    AuditEvent::MessageSent(from, to) => "from=" + from + " to=" + to
    AuditEvent::PermissionCheck(agent, resource, allowed) =>
      "agent=" +
      agent +
      " resource=" +
      resource +
      " allowed=" +
      allowed.to_string()
  }
  name + " " + detail
}
