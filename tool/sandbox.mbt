///|
/// Tool sandbox — enforces execution policies, quotas, and path restrictions.

///|
pub struct SandboxedResult {
  output : String
  allowed : Bool
  blocked_reason : String?
}

///|
pub fn SandboxedResult::allowed(output : String) -> SandboxedResult {
  { output, allowed: true, blocked_reason: None }
}

///|
pub fn SandboxedResult::blocked(reason : String) -> SandboxedResult {
  { output: "", allowed: false, blocked_reason: Some(reason) }
}

///|
pub struct ToolSandbox {
  registry : ToolRegistry
  mut call_count : Int
  max_calls : Int
  timeout_ms : Int
  allowed_tools : Array[String]
  denied_tools : Array[String]
  mut allowed_path_prefix : String?
  audit_log : Array[String]
}

///|
pub fn ToolSandbox::new(registry : ToolRegistry) -> ToolSandbox {
  {
    registry,
    call_count: 0,
    max_calls: 50,
    timeout_ms: 30000,
    allowed_tools: [],
    denied_tools: [],
    allowed_path_prefix: None,
    audit_log: [],
  }
}

///|
pub fn ToolSandbox::with_limits(
  registry : ToolRegistry,
  max_calls : Int,
  timeout_ms : Int,
) -> ToolSandbox {
  {
    registry,
    call_count: 0,
    max_calls,
    timeout_ms,
    allowed_tools: [],
    denied_tools: [],
    allowed_path_prefix: None,
    audit_log: [],
  }
}

///|
pub fn ToolSandbox::deny_tool(self : ToolSandbox, name : String) -> Unit {
  self.denied_tools.push(name)
}

///|
pub fn ToolSandbox::allow_tool(self : ToolSandbox, name : String) -> Unit {
  self.allowed_tools.push(name)
}

///|
pub fn ToolSandbox::restrict_path(self : ToolSandbox, prefix : String) -> Unit {
  self.allowed_path_prefix = Some(prefix)
}

///|
pub fn ToolSandbox::reset_count(self : ToolSandbox) -> Unit {
  self.call_count = 0
}

///|
/// Execute a tool through the sandbox.
pub fn ToolSandbox::execute(
  self : ToolSandbox,
  tool_name : String,
  arguments : String,
) -> SandboxedResult {
  if self.call_count >= self.max_calls {
    return SandboxedResult::blocked(
      "tool call quota exceeded (max: " + self.max_calls.to_string() + ")",
    )
  }
  for d in self.denied_tools {
    if d == tool_name {
      return SandboxedResult::blocked("tool '" + tool_name + "' is denied")
    }
  }
  if self.allowed_tools.length() > 0 {
    let mut found = false
    for a in self.allowed_tools {
      if a == tool_name {
        found = true
        break
      }
    }
    if !found {
      return SandboxedResult::blocked(
        "tool '" + tool_name + "' is not in allowed list",
      )
    }
  }
  if self.allowed_path_prefix is Some(prefix) {
    let restricted = tool_name == "read" ||
      tool_name == "write" ||
      tool_name == "edit" ||
      tool_name == "ls" ||
      tool_name == "stat"
    if restricted && !arguments.contains(prefix) {
      return SandboxedResult::blocked(
        "path not allowed: must be under '" + prefix + "'",
      )
    }
  }
  self.call_count = self.call_count + 1
  self.audit_log.push("call #" + self.call_count.to_string() + ": " + tool_name)
  match self.registry.execute(tool_name, arguments) {
    Some(output) => SandboxedResult::allowed(output)
    None => SandboxedResult::blocked("tool '" + tool_name + "' not found")
  }
}

///|
pub fn ToolSandbox::audit(self : ToolSandbox) -> Array[String] {
  self.audit_log
}

///|
pub fn ToolSandbox::remaining(self : ToolSandbox) -> Int {
  self.max_calls - self.call_count
}
