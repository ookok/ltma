///|
/// Planner — decomposes goals into executable Workflows.
fn split_parts(text : String) -> Array[String] {
  let parts = text.split(" and ")
  let result : Array[String] = []
  for p in parts {
    let trimmed = p.trim().to_owned()
    if trimmed != "" {
      let sub = trimmed.split(" then ")
      for s in sub {
        let sub_trimmed = s.trim().to_owned()
        if sub_trimmed != "" {
          result.push(sub_trimmed)
        }
      }
    }
  }
  result
}

///|
pub struct Planner {
  router : AgentRouter
  llm_provider : @llm.LLMProviderHandle?
}

///|
pub fn Planner::new(router : AgentRouter) -> Planner {
  { router, llm_provider: None }
}

///|
pub fn Planner::with_llm(
  self : Planner,
  provider : @llm.LLMProviderHandle,
) -> Planner {
  { router: self.router, llm_provider: Some(provider) }
}

///|
/// Plan a goal into a Workflow using keyword-based decomposition.
pub fn Planner::plan(self : Planner, goal : String) -> Workflow {
  let parts = split_parts(goal)
  let wf = Workflow::new()

  for i = 0; i < parts.length(); i = i + 1 {
    let task = parts[i]
    match self.router.route(task) {
      Some(name) => wf.add(StepDef::agent(name))
      None => wf.add(StepDef::route(task))
    }
  }

  if wf.count() == 0 {
    wf.add(StepDef::route(goal))
  }

  wf
}

///|
/// Plan with LLM decomposition. Falls back to keyword-based if no LLM set.
pub fn Planner::plan_with_llm(self : Planner, goal : String) -> Workflow {
  match self.llm_provider {
    Some(provider) => {
      let sys_msg = @llm.ChatMessage::new(
        @llm.ChatRole::system(),
        "Decompose goals into 1-5 sub-tasks separated by '|'. Example: 'research topic|write code|test results'",
      )
      let user_msg = @llm.ChatMessage::new(@llm.ChatRole::user(), goal)
      let resp = provider.chat([sys_msg, user_msg], None)
      let sub_goals = resp.content.split("|")
      let wf = Workflow::new()

      for sg in sub_goals {
        let sub = sg.trim().to_owned()
        if sub != "" {
          match self.router.route(sub) {
            Some(name) => wf.add(StepDef::agent(name))
            None => wf.add(StepDef::route(sub))
          }
        }
      }

      if wf.count() == 0 {
        wf.add(StepDef::route(goal))
      }

      wf
    }
    None => self.plan(goal)
  }
}
