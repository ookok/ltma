///|
/// Core types for the LTMA framework.

///|
pub struct AgentId {
  name : String
  version : String
  module_name : String
}

///|
pub fn AgentId::create(
  name : String,
  version : String,
  module_name : String,
) -> AgentId {
  { name, version, module_name }
}

///|
pub fn AgentId::to_string(self : AgentId) -> String {
  "\{self.module_name}/\{self.name}@\{self.version}"
}

///|
pub struct IsolationLevel {
  code : Int
}

///|
pub fn IsolationLevel::in_process() -> IsolationLevel {
  { code: 0 }
}

///|
pub fn IsolationLevel::wasm_sandbox() -> IsolationLevel {
  { code: 1 }
}

///|
pub fn IsolationLevel::process() -> IsolationLevel {
  { code: 2 }
}

///|
pub struct Target {
  code : Int
}

///|
pub fn Target::native() -> Target {
  { code: 0 }
}

///|
pub fn Target::wasm() -> Target {
  { code: 1 }
}

///|
pub fn Target::js() -> Target {
  { code: 2 }
}

///|
pub struct AgentStatus {
  code : Int
  message : String?
}

///|
pub fn AgentStatus::new_st() -> AgentStatus {
  { code: 0, message: None }
}

///|
pub fn AgentStatus::discovered() -> AgentStatus {
  { code: 1, message: None }
}

///|
pub fn AgentStatus::initializing() -> AgentStatus {
  { code: 2, message: None }
}

///|
pub fn AgentStatus::idle() -> AgentStatus {
  { code: 3, message: None }
}

///|
pub fn AgentStatus::running() -> AgentStatus {
  { code: 4, message: None }
}

///|
pub fn AgentStatus::completed() -> AgentStatus {
  { code: 5, message: None }
}

///|
pub fn AgentStatus::shutdown_st() -> AgentStatus {
  { code: 6, message: None }
}

///|
pub fn AgentStatus::error_st(msg : String) -> AgentStatus {
  { code: 7, message: Some(msg) }
}

///|
pub fn AgentStatus::is_new(self : AgentStatus) -> Bool {
  self.code == 0
}

///|
pub fn AgentStatus::is_idle(self : AgentStatus) -> Bool {
  self.code == 3
}

///|
pub fn AgentStatus::is_shutdown(self : AgentStatus) -> Bool {
  self.code == 6
}

///|
pub fn AgentStatus::is_error(self : AgentStatus) -> Bool {
  self.code == 7
}

///|
pub struct AgentMetadata {
  id : AgentId
  description : String
  capabilities : Array[String]
  isolation : IsolationLevel
  target : Target
  version : String
}

///|
pub fn AgentMetadata::create(
  id : AgentId,
  description : String,
  capabilities : Array[String],
  isolation : IsolationLevel,
  target : Target,
  version : String,
) -> AgentMetadata {
  { id, description, capabilities, isolation, target, version }
}

///|
pub struct ToolCall {
  id : String
  name : String
  arguments : String
}

///|
pub fn ToolCall::create(
  id : String,
  name : String,
  arguments : String,
) -> ToolCall {
  { id, name, arguments }
}

///|
pub struct ToolResult {
  id : String
  success : Bool
  output : String
  error : String?
}

///|
pub fn ToolResult::create(
  id : String,
  success : Bool,
  output : String,
  error : String?,
) -> ToolResult {
  { id, success, output, error }
}

///|
pub struct ToolDefinition {
  name : String
  description : String
  parameters : String
  strict : Bool
}

///|
pub fn ToolDefinition::create(
  name : String,
  description : String,
  parameters : String,
  strict : Bool,
) -> ToolDefinition {
  { name, description, parameters, strict }
}

///|
pub struct SearchResult {
  key : String
  score : Double
  content : String
}

///|
pub struct AgentContext {
  agent_id : AgentId
  host_name : String
  session_id : String
  params : Map[String, String]
}

///|
pub fn AgentContext::new(agent_id : AgentId) -> AgentContext {
  { agent_id, host_name: "ltma", session_id: "", params: Map([]) }
}

///|
/// Message — struct-based with kind discriminator
pub struct Message {
  kind : Int
  text_val : String?
  sys_kind : Int?
  sys_status : AgentStatus?
}

///|
pub fn Message::text(content : String) -> Message {
  { kind: 0, text_val: Some(content), sys_kind: None, sys_status: None }
}

///|
pub fn Message::is_text(self : Message) -> Bool {
  self.kind == 0
}

///|
pub fn Message::get_text(self : Message) -> String {
  self.text_val.unwrap_or("")
}

///|
pub fn Message::system_shutdown() -> Message {
  { kind: 1, text_val: None, sys_kind: Some(0), sys_status: None }
}

///|
pub fn Message::system_status_request() -> Message {
  { kind: 1, text_val: None, sys_kind: Some(1), sys_status: None }
}

///|
pub fn Message::system_status_response(st : AgentStatus) -> Message {
  { kind: 1, text_val: None, sys_kind: Some(2), sys_status: Some(st) }
}

///|
pub fn Message::is_system_status_request(self : Message) -> Bool {
  self.kind == 1 && self.sys_kind == Some(1)
}

///|
pub fn Message::is_system_shutdown(self : Message) -> Bool {
  self.kind == 1 && self.sys_kind == Some(0)
}
