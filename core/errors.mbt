///|
/// Error types for the LTMA framework.

///|
pub enum PipelineError {
  AgentNotFound(String)
  ActivationFailed(String)
  IsolationError(String)
  Timeout(String)
  InvalidState(String)
  Unknown(String)
}
