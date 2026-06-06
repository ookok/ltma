///|
/// Agent-level permission system.

///|
pub enum Permission {
  Allow
  Deny
}

///|
pub struct AgentPermission {
  agent_name : String
  allowed_tools : Array[String]
  denied_tools : Array[String]
  allowed_agents : Array[String]
  max_tool_calls : Int
}

///|
pub fn AgentPermission::new(agent_name : String) -> AgentPermission {
  {
    agent_name,
    allowed_tools: [],
    denied_tools: [],
    allowed_agents: [],
    max_tool_calls: 50,
  }
}

///|
pub fn AgentPermission::allow_tool(
  self : AgentPermission,
  tool : String,
) -> Unit {
  self.allowed_tools.push(tool)
}

///|
pub fn AgentPermission::deny_tool(
  self : AgentPermission,
  tool : String,
) -> Unit {
  self.denied_tools.push(tool)
}

///|
pub fn AgentPermission::allow_agent(
  self : AgentPermission,
  agent : String,
) -> Unit {
  self.allowed_agents.push(agent)
}

///|
pub fn AgentPermission::can_use_tool(
  self : AgentPermission,
  tool : String,
) -> Permission {
  for d in self.denied_tools {
    if d == tool {
      return Permission::Deny
    }
  }
  if self.allowed_tools.length() > 0 {
    for a in self.allowed_tools {
      if a == tool {
        return Permission::Allow
      }
    }
    Permission::Deny
  } else {
    Permission::Allow
  }
}

///|
/// Permission manager — governs what agents can do.
pub struct PermissionManager {
  entries : Map[String, AgentPermission]
  default_action : Permission
}

///|
pub fn PermissionManager::new() -> PermissionManager {
  { entries: Map([]), default_action: Permission::Deny }
}

///|
pub fn PermissionManager::permissive() -> PermissionManager {
  { entries: Map([]), default_action: Permission::Allow }
}

///|
pub fn PermissionManager::register(
  self : PermissionManager,
  perm : AgentPermission,
) -> Unit {
  self.entries[perm.agent_name] = perm
}

///|
pub fn PermissionManager::check_tool(
  self : PermissionManager,
  agent_name : String,
  tool : String,
) -> Permission {
  match self.entries.get(agent_name) {
    Some(perm) => perm.can_use_tool(tool)
    None => self.default_action
  }
}
