///|
/// Contract types — using concrete AgentHandle (closures).

///|
pub struct AgentHandle {
  id_fn : () -> String
  metadata_fn : () -> AgentMetadata
  init_fn : (AgentContext) -> Unit
  run_fn : (Message) -> Message
  shutdown_fn : () -> Unit
  status_fn : () -> AgentStatus
  execute_tool_fn : (ToolCall) -> ToolResult
}

///|
pub fn AgentHandle::id(self : AgentHandle) -> String {
  (self.id_fn)()
}

///|
pub fn AgentHandle::metadata(self : AgentHandle) -> AgentMetadata {
  (self.metadata_fn)()
}

///|
pub fn AgentHandle::init(self : AgentHandle, ctx : AgentContext) -> Unit {
  (self.init_fn)(ctx)
}

///|
pub fn AgentHandle::run(self : AgentHandle, input : Message) -> Message {
  (self.run_fn)(input)
}

///|
pub fn AgentHandle::shutdown(self : AgentHandle) -> Unit {
  (self.shutdown_fn)()
}

///|
pub fn AgentHandle::status(self : AgentHandle) -> AgentStatus {
  (self.status_fn)()
}

///|
pub fn AgentHandle::execute_tool(
  self : AgentHandle,
  call : ToolCall,
) -> ToolResult {
  (self.execute_tool_fn)(call)
}

///|
pub fn[T] make_handle(
  agent : T,
  id_fn : (T) -> String,
  metadata_fn : (T) -> AgentMetadata,
  init_fn : (T, AgentContext) -> Unit,
  run_fn : (T, Message) -> Message,
  shutdown_fn : (T) -> Unit,
  status_fn : (T) -> AgentStatus,
  execute_tool_fn : (T, ToolCall) -> ToolResult,
) -> AgentHandle {
  let a = agent
  AgentHandle::{
    id_fn: fn() { id_fn(a) },
    metadata_fn: fn() { metadata_fn(a) },
    init_fn: fn(ctx) { init_fn(a, ctx) },
    run_fn: fn(msg) { run_fn(a, msg) },
    shutdown_fn: fn() { shutdown_fn(a) },
    status_fn: fn() { status_fn(a) },
    execute_tool_fn: fn(call) { execute_tool_fn(a, call) },
  }
}
