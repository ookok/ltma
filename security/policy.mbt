///|
/// Security policy definitions for the LTMA framework.

///|
pub enum PolicyAction {
  Allow
  Deny
  Log
  RequireApproval
}

///|
pub struct SecurityPolicy {
  name : String
  max_tool_calls_per_run : Int
  require_human_approval : Array[String]
  blocked_tools : Array[String]
  blocked_agents : Array[String]
  allowed_networks : Array[String]
  max_message_size : Int
}

///|
pub fn SecurityPolicy::default() -> SecurityPolicy {
  {
    name: "default",
    max_tool_calls_per_run: 25,
    require_human_approval: ["shell", "write", "edit"],
    blocked_tools: [],
    blocked_agents: [],
    allowed_networks: ["none"],
    max_message_size: 65536,
  }
}

///|
pub fn SecurityPolicy::restrictive() -> SecurityPolicy {
  {
    name: "restrictive",
    max_tool_calls_per_run: 5,
    require_human_approval: ["shell", "write", "edit", "read", "ls", "stat"],
    blocked_tools: [],
    blocked_agents: [],
    allowed_networks: ["none"],
    max_message_size: 16384,
  }
}

///|
pub fn SecurityPolicy::permissive() -> SecurityPolicy {
  {
    name: "permissive",
    max_tool_calls_per_run: 100,
    require_human_approval: ["shell"],
    blocked_tools: [],
    blocked_agents: [],
    allowed_networks: ["all"],
    max_message_size: 1048576,
  }
}

///|
pub struct PolicyEngine {
  policy : SecurityPolicy
}

///|
pub fn PolicyEngine::new(policy : SecurityPolicy) -> PolicyEngine {
  { policy, }
}

///|
pub fn PolicyEngine::check_tool(
  self : PolicyEngine,
  tool : String,
) -> PolicyAction {
  for b in self.policy.blocked_tools {
    if b == tool {
      return PolicyAction::Deny
    }
  }
  for a in self.policy.require_human_approval {
    if a == tool {
      return PolicyAction::RequireApproval
    }
  }
  PolicyAction::Allow
}

///|
pub fn PolicyEngine::check_message_size(
  self : PolicyEngine,
  size : Int,
) -> PolicyAction {
  if size > self.policy.max_message_size {
    PolicyAction::Deny
  } else {
    PolicyAction::Allow
  }
}

///|
pub fn PolicyEngine::check_agent(
  self : PolicyEngine,
  agent_name : String,
) -> PolicyAction {
  for b in self.policy.blocked_agents {
    if b == agent_name {
      return PolicyAction::Deny
    }
  }
  PolicyAction::Allow
}
