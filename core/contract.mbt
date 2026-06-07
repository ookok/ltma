///|
/// Contract types — MAF-style pipeline segments.
///
/// MAF pipeline: Host → HostSideAdapter → Contract → AddInSideAdapter → AddIn
/// LTMA pipeline: Host → HostSideAdapter → ContractHandle → AddInSideAdapter → Agent

///|
/// ContractHandle — the MAF-equivalent of `IContract`.
/// This is the minimal communication boundary between host and add-in sides.
pub struct ContractHandle {
  init_fn : (AgentContext) -> Unit
  run_fn : (Message) -> Message
  shutdown_fn : () -> Unit
  status_fn : () -> AgentStatus
  execute_tool_fn : (ToolCall) -> ToolResult
}

///|
pub fn ContractHandle::create(
  init_fn : (AgentContext) -> Unit,
  run_fn : (Message) -> Message,
  shutdown_fn : () -> Unit,
  status_fn : () -> AgentStatus,
  execute_tool_fn : (ToolCall) -> ToolResult,
) -> ContractHandle {
  { init_fn, run_fn, shutdown_fn, status_fn, execute_tool_fn }
}

///|
pub fn ContractHandle::init(self : ContractHandle, ctx : AgentContext) -> Unit {
  (self.init_fn)(ctx)
}

///|
pub fn ContractHandle::run(self : ContractHandle, input : Message) -> Message {
  (self.run_fn)(input)
}

///|
pub fn ContractHandle::shutdown(self : ContractHandle) -> Unit {
  (self.shutdown_fn)()
}

///|
pub fn ContractHandle::status(self : ContractHandle) -> AgentStatus {
  (self.status_fn)()
}

///|
pub fn ContractHandle::execute_tool(
  self : ContractHandle,
  call : ToolCall,
) -> ToolResult {
  (self.execute_tool_fn)(call)
}

///|
/// AgentHandle — the MAF-equivalent of `HostViewOfAddIn`.
/// Combines identity/metadata with the contract operations.
pub struct AgentHandle {
  id_fn : () -> String
  metadata_fn : () -> AgentMetadata
  contract_fn : () -> ContractHandle
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
pub fn AgentHandle::contract(self : AgentHandle) -> ContractHandle {
  (self.contract_fn)()
}

///|
pub fn AgentHandle::init(self : AgentHandle, ctx : AgentContext) -> Unit {
  (self.contract_fn)().init(ctx)
}

///|
pub fn AgentHandle::run(self : AgentHandle, input : Message) -> Message {
  (self.contract_fn)().run(input)
}

///|
pub fn AgentHandle::shutdown(self : AgentHandle) -> Unit {
  (self.contract_fn)().shutdown()
}

///|
pub fn AgentHandle::status(self : AgentHandle) -> AgentStatus {
  (self.contract_fn)().status()
}

///|
pub fn AgentHandle::execute_tool(
  self : AgentHandle,
  call : ToolCall,
) -> ToolResult {
  (self.contract_fn)().execute_tool(call)
}

///|
pub fn AgentHandle::create(
  id_fn : () -> String,
  metadata_fn : () -> AgentMetadata,
  contract_fn : () -> ContractHandle,
) -> AgentHandle {
  { id_fn, metadata_fn, contract_fn }
}

///|
/// Build an AgentHandle from a ContractHandle plus identity/metadata.
pub fn wrap_contract(
  id : String,
  meta : AgentMetadata,
  contract : ContractHandle,
) -> AgentHandle {
  AgentHandle::create(fn() { id }, fn() { meta }, fn() { contract })
}

///|
/// Build an AgentHandle from individual closures (MAF make_handle pattern).
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
  let contract = ContractHandle::create(
    fn(ctx) { init_fn(a, ctx) },
    fn(msg) { run_fn(a, msg) },
    fn() { shutdown_fn(a) },
    fn() { status_fn(a) },
    fn(call) { execute_tool_fn(a, call) },
  )
  AgentHandle::create(fn() { id_fn(a) }, fn() { metadata_fn(a) }, fn() {
    contract
  })
}

///|
/// AsyncContractHandle — async version of the contract boundary.
pub struct AsyncContractHandle {
  init_fn : (AgentContext) -> Unit
  run_fn : async (Message) -> Message
  shutdown_fn : () -> Unit
  status_fn : () -> AgentStatus
  execute_tool_fn : (ToolCall) -> ToolResult
}

///|
pub fn AsyncContractHandle::create(
  init_fn : (AgentContext) -> Unit,
  run_fn : async (Message) -> Message,
  shutdown_fn : () -> Unit,
  status_fn : () -> AgentStatus,
  execute_tool_fn : (ToolCall) -> ToolResult,
) -> AsyncContractHandle {
  { init_fn, run_fn, shutdown_fn, status_fn, execute_tool_fn }
}

///|
pub fn AsyncContractHandle::init(
  self : AsyncContractHandle,
  ctx : AgentContext,
) -> Unit {
  (self.init_fn)(ctx)
}

///|
pub async fn AsyncContractHandle::run(
  self : AsyncContractHandle,
  input : Message,
) -> Message {
  (self.run_fn)(input)
}

///|
pub fn AsyncContractHandle::shutdown(self : AsyncContractHandle) -> Unit {
  (self.shutdown_fn)()
}

///|
pub fn AsyncContractHandle::status(self : AsyncContractHandle) -> AgentStatus {
  (self.status_fn)()
}

///|
pub fn AsyncContractHandle::execute_tool(
  self : AsyncContractHandle,
  call : ToolCall,
) -> ToolResult {
  (self.execute_tool_fn)(call)
}

///|
/// AsyncAgentHandle — async version with identity/metadata.
pub struct AsyncAgentHandle {
  id_fn : () -> String
  metadata_fn : () -> AgentMetadata
  contract_fn : () -> AsyncContractHandle
}

///|
pub fn AsyncAgentHandle::id(self : AsyncAgentHandle) -> String {
  (self.id_fn)()
}

///|
pub fn AsyncAgentHandle::metadata(self : AsyncAgentHandle) -> AgentMetadata {
  (self.metadata_fn)()
}

///|
pub fn AsyncAgentHandle::contract(
  self : AsyncAgentHandle,
) -> AsyncContractHandle {
  (self.contract_fn)()
}

///|
pub fn AsyncAgentHandle::init(
  self : AsyncAgentHandle,
  ctx : AgentContext,
) -> Unit {
  (self.contract_fn)().init(ctx)
}

///|
pub async fn AsyncAgentHandle::run(
  self : AsyncAgentHandle,
  input : Message,
) -> Message {
  (self.contract_fn)().run(input)
}

///|
pub fn AsyncAgentHandle::shutdown(self : AsyncAgentHandle) -> Unit {
  (self.contract_fn)().shutdown()
}

///|
pub fn AsyncAgentHandle::status(self : AsyncAgentHandle) -> AgentStatus {
  (self.contract_fn)().status()
}

///|
pub fn AsyncAgentHandle::execute_tool(
  self : AsyncAgentHandle,
  call : ToolCall,
) -> ToolResult {
  (self.contract_fn)().execute_tool(call)
}

///|
pub fn AsyncAgentHandle::create(
  id_fn : () -> String,
  metadata_fn : () -> AgentMetadata,
  contract_fn : () -> AsyncContractHandle,
) -> AsyncAgentHandle {
  { id_fn, metadata_fn, contract_fn }
}

///|
pub fn wrap_async_contract(
  id : String,
  meta : AgentMetadata,
  contract : AsyncContractHandle,
) -> AsyncAgentHandle {
  AsyncAgentHandle::create(fn() { id }, fn() { meta }, fn() { contract })
}

///|
pub fn[T] make_async_handle(
  agent : T,
  id_fn : (T) -> String,
  metadata_fn : (T) -> AgentMetadata,
  init_fn : (T, AgentContext) -> Unit,
  run_fn : async (T, Message) -> Message,
  shutdown_fn : (T) -> Unit,
  status_fn : (T) -> AgentStatus,
  execute_tool_fn : (T, ToolCall) -> ToolResult,
) -> AsyncAgentHandle {
  let a = agent
  let contract = AsyncContractHandle::create(
    fn(ctx) { init_fn(a, ctx) },
    async fn(msg) { run_fn(a, msg) },
    fn() { shutdown_fn(a) },
    fn() { status_fn(a) },
    fn(call) { execute_tool_fn(a, call) },
  )
  AsyncAgentHandle::create(fn() { id_fn(a) }, fn() { metadata_fn(a) }, fn() {
    contract
  })
}
