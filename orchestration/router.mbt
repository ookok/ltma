///|
/// Agent router — capability-based task routing.

///|
pub struct AgentRegistration {
  agent_name : String
  capabilities : Array[String]
}

///|
pub struct AgentRouter {
  agents : Array[AgentRegistration]
}

///|
pub fn AgentRouter::new() -> AgentRouter {
  { agents: [] }
}

///|
pub fn AgentRouter::register(
  self : AgentRouter,
  name : String,
  capabilities : Array[String],
) -> Unit {
  self.agents.push({ agent_name: name, capabilities })
}

///|
pub fn AgentRouter::route(self : AgentRouter, task : String) -> String? {
  let task_lower = task.to_lower()
  let mut best_score = 0
  let mut best_agent : String? = None

  for reg in self.agents {
    let score = score_match(task_lower, reg.capabilities)
    if score > best_score {
      best_score = score
      best_agent = Some(reg.agent_name)
    }
  }
  best_agent
}

///|
pub fn AgentRouter::list_agents(self : AgentRouter) -> Array[AgentRegistration] {
  self.agents
}

///|
fn score_match(task : String, capabilities : Array[String]) -> Int {
  let mut score = 0
  for cap in capabilities {
    let cap_lower = cap.to_lower()
    if task.contains(cap_lower) {
      score = score + 10
    }
    // Check task keywords against capability words
    let task_words = task.split(" ")
    for word in task_words {
      if cap_lower.contains(word.to_lower()) ||
        word.to_lower().contains(cap_lower) {
        score = score + 5
      }
    }
  }
  score
}
