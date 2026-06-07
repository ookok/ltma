///|
/// HostViewOfAddIn — MAF HostViewOfAddIn equivalent.
///
/// In MAF, the host's AppDomain gets a HostViewOfAddIn — a thin view
/// of the add-in's capabilities without exposing the full contract.
/// The actual `AgentHandle` already fills this role, but this file
/// adds a generic `HostView` that can wrap any contract handle
/// to present a capabilities-oriented API to the host.

///|
/// Capability — a named operation an agent can perform.
pub struct Capability {
  name : String
  description : String
}

///|
pub fn Capability::new(name : String, description : String) -> Capability {
  { name, description }
}

///|
/// HostViewOfAddIn — the host's view of an activated add-in.
///
/// Wraps a ContractHandle and presents a cleaned-up API for the host.
pub struct HostViewOfAddIn {
  agent_id : AgentId
  metadata : AgentMetadata
  contract : ContractHandle
  capabilities : Array[Capability]
}

///|
pub fn HostViewOfAddIn::create(
  agent_id : AgentId,
  metadata : AgentMetadata,
  contract : ContractHandle,
  capabilities : Array[Capability],
) -> HostViewOfAddIn {
  { agent_id, metadata, contract, capabilities }
}

///|
pub fn HostViewOfAddIn::id(self : HostViewOfAddIn) -> AgentId {
  self.agent_id
}

///|
pub fn HostViewOfAddIn::call(self : HostViewOfAddIn, msg : Message) -> Message {
  self.contract.run(msg)
}

///|
pub fn HostViewOfAddIn::shutdown(self : HostViewOfAddIn) -> Unit {
  self.contract.shutdown()
}

///|
pub fn HostViewOfAddIn::status(self : HostViewOfAddIn) -> AgentStatus {
  self.contract.status()
}

///|
pub fn HostViewOfAddIn::execute_tool(
  self : HostViewOfAddIn,
  call : ToolCall,
) -> ToolResult {
  self.contract.execute_tool(call)
}

///|
pub fn HostViewOfAddIn::has_capability(
  self : HostViewOfAddIn,
  name : String,
) -> Bool {
  for cap in self.capabilities {
    if cap.name == name {
      return true
    }
  }
  false
}

///|
pub fn HostViewOfAddIn::list_capabilities(
  self : HostViewOfAddIn,
) -> Array[Capability] {
  self.capabilities
}
