///|
/// Permission system for tool access control.

///|
pub enum ToolPermission {
  Allowed
  Denied
}

///|
/// Identity of an agent requesting tool access.
pub struct AgentIdentity {
  name : String
  pkg : String
}

///|
pub fn AgentIdentity::new(name : String, pkg : String) -> AgentIdentity {
  { name, pkg }
}

///|
/// PermissionMatrix — agent-to-tool access control.
pub struct PermissionMatrix {
  mut default_policy : ToolPermission
  rules : Map[String, Map[String, ToolPermission]]
}

///|
pub fn PermissionMatrix::new(
  default_policy : ToolPermission,
) -> PermissionMatrix {
  { default_policy, rules: Map([]) }
}

///|
pub fn PermissionMatrix::set_default(
  self : PermissionMatrix,
  policy : ToolPermission,
) -> Unit {
  self.default_policy = policy
}

///|
/// Allow an agent to use a specific tool.
pub fn PermissionMatrix::allow(
  self : PermissionMatrix,
  agent_name : String,
  tool_name : String,
) -> Unit {
  let agent_rules = match self.rules.get(agent_name) {
    Some(r) => r
    None => Map([])
  }
  agent_rules[tool_name] = ToolPermission::Allowed
  self.rules[agent_name] = agent_rules
}

///|
/// Deny an agent from using a specific tool.
pub fn PermissionMatrix::deny(
  self : PermissionMatrix,
  agent_name : String,
  tool_name : String,
) -> Unit {
  let agent_rules = match self.rules.get(agent_name) {
    Some(r) => r
    None => Map([])
  }
  agent_rules[tool_name] = ToolPermission::Denied
  self.rules[agent_name] = agent_rules
}

///|
/// Remove a specific tool rule for an agent (reverts to default).
pub fn PermissionMatrix::clear_rule(
  self : PermissionMatrix,
  agent_name : String,
  tool_name : String,
) -> Unit {
  match self.rules.get(agent_name) {
    Some(r) => {
      r.remove(tool_name)
      if r.length() == 0 {
        self.rules.remove(agent_name)
      }
    }
    None => ()
  }
}

///|
/// Check if an agent is allowed to use a tool.
pub fn PermissionMatrix::check(
  self : PermissionMatrix,
  agent_name : String,
  tool_name : String,
) -> Bool {
  match self.rules.get(agent_name) {
    Some(agent_rules) =>
      match agent_rules.get(tool_name) {
        Some(perm) => perm is ToolPermission::Allowed
        None => self.default_policy is ToolPermission::Allowed
      }
    None => self.default_policy is ToolPermission::Allowed
  }
}

///|
/// List all denied tools for a given agent.
pub fn PermissionMatrix::denied_tools(
  self : PermissionMatrix,
  agent_name : String,
) -> Array[String] {
  let result : Array[String] = []
  match self.rules.get(agent_name) {
    Some(agent_rules) =>
      for tool_name, perm in agent_rules {
        if perm is ToolPermission::Denied {
          result.push(tool_name)
        }
      }
    None => ()
  }
  result
}

///|
/// List all explicitly allowed tools for a given agent.
pub fn PermissionMatrix::allowed_tools(
  self : PermissionMatrix,
  agent_name : String,
) -> Array[String] {
  let result : Array[String] = []
  match self.rules.get(agent_name) {
    Some(agent_rules) =>
      for tool_name, perm in agent_rules {
        if perm is ToolPermission::Allowed {
          result.push(tool_name)
        }
      }
    None => ()
  }
  result
}

///|
/// Count total rules across all agents.
pub fn PermissionMatrix::count(self : PermissionMatrix) -> Int {
  let mut n = 0
  for _, agent_rules in self.rules {
    n = n + agent_rules.length()
  }
  n
}

///|
/// Wrapper that checks permissions before executing tools.
pub fn execute_with_permissions(
  registry : ToolRegistry,
  matrix : PermissionMatrix,
  agent_name : String,
  tool_name : String,
  input : String,
) -> String? {
  if matrix.check(agent_name, tool_name) {
    registry.execute(tool_name, input)
  } else {
    None
  }
}
