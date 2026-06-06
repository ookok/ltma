///|
/// Agent handoff, workflow, and routing definitions.

///|
pub struct HandoffDef {
  from : String
  to : String
  reason : String
}

///|
pub fn HandoffDef::new(
  from : String,
  to : String,
  reason : String,
) -> HandoffDef {
  { from, to, reason }
}

///|
/// Step definition for workflows
pub struct StepDef {
  kind : Int
  name : String?
  handoff : HandoffDef?
  parallel_names : Array[String]?
  route_task : String?
}

///|
pub fn StepDef::agent(name : String) -> StepDef {
  {
    kind: 0,
    name: Some(name),
    handoff: None,
    parallel_names: None,
    route_task: None,
  }
}

///|
pub fn StepDef::handoff(h : HandoffDef) -> StepDef {
  {
    kind: 1,
    name: None,
    handoff: Some(h),
    parallel_names: None,
    route_task: None,
  }
}

///|
pub fn StepDef::parallel(names : Array[String]) -> StepDef {
  {
    kind: 2,
    name: None,
    handoff: None,
    parallel_names: Some(names),
    route_task: None,
  }
}

///|
pub fn StepDef::route(task : String) -> StepDef {
  {
    kind: 3,
    name: None,
    handoff: None,
    parallel_names: None,
    route_task: Some(task),
  }
}

///|
/// Workflow: sequential execution of agents
pub struct Workflow {
  steps : Array[StepDef]
}

///|
pub fn Workflow::new() -> Workflow {
  { steps: [] }
}

///|
pub fn Workflow::add(self : Workflow, step : StepDef) -> Unit {
  self.steps.push(step)
}

///|
pub fn Workflow::count(self : Workflow) -> Int {
  self.steps.length()
}

///|
/// Execute a workflow, optionally using a router for dynamic dispatch.
pub fn execute_workflow(
  wf : Workflow,
  host : @host.AgentHost,
  input : String,
  router : AgentRouter?,
) -> Array[String] {
  let results : Array[String] = []
  for step in wf.steps {
    if step.kind == 0 {
      let name = step.name.unwrap_or("")
      results.push(execute_single(name, host, input))
    } else if step.kind == 1 && step.handoff is Some(_) {
      let h = step.handoff.unwrap_or(HandoffDef::new("", "", ""))
      results.push("[handoff: \{h.from} -> \{h.to} (\{h.reason})]")
    } else if step.kind == 2 && step.parallel_names is Some(_) {
      let names = step.parallel_names.unwrap_or([])
      results.push("[parallel: \{names.length()} agents]")
    } else if step.kind == 3 {
      let task = step.route_task.unwrap_or("")
      match router {
        Some(r) =>
          match r.route(task) {
            Some(name) => results.push(execute_single(name, host, input))
            None => results.push("no agent found for task: \{task}")
          }
        None => results.push("router not configured for task: \{task}")
      }
    }
  }
  results
}

///|
fn execute_single(
  name : String,
  host : @host.AgentHost,
  input : String,
) -> String {
  let id = @core.AgentId::create(name, "0.1.0", "livingtree/ltma")
  match host.activate(id) {
    Some(adapter) => {
      let resp = adapter.call(@core.Message::text(input))
      adapter.shutdown()
      if resp.is_text() {
        resp.get_text()
      } else {
        "<non-text>"
      }
    }
    None => "agent not found: \{name}"
  }
}
