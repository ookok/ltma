///|
/// task tool — delegate sub-tasks to other agents.

///|
pub fn task_tool(agent_name : String, task : String) -> String {
  "[task: " + agent_name + " would run: " + task + "]"
}

///|
pub fn task_tool_json(input : String) -> String {
  let agent = extract_field(input, "agent").unwrap_or("echo")
  let task = extract_field(input, "task").unwrap_or("")
  task_tool(agent, task)
}

///|
pub fn task_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create("task", "Delegate a sub-task to another agent", "{type:object,properties:{agent:{type:string},task:{type:string}}}", false)
}
