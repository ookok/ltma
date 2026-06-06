///|
/// Provider fallback chain with circuit breaker.

///|
/// Circuit breaker state.
pub enum CircuitState {
  Closed
  Open
  HalfOpen
}

///|
/// Circuit breaker — tracks failures and stops calling after a threshold.
pub struct CircuitBreaker {
  mut state : CircuitState
  mut failures : Int
  threshold : Int
}

///|
pub fn CircuitBreaker::new(threshold : Int) -> CircuitBreaker {
  { state: CircuitState::Closed, failures: 0, threshold }
}

///|
pub fn CircuitBreaker::record_success(self : CircuitBreaker) -> Unit {
  self.failures = 0
  self.state = CircuitState::Closed
}

///|
pub fn CircuitBreaker::record_failure(self : CircuitBreaker) -> Unit {
  self.failures = self.failures + 1
  if self.failures >= self.threshold {
    self.state = CircuitState::Open
  }
}

///|
pub fn CircuitBreaker::is_open(self : CircuitBreaker) -> Bool {
  self.state is CircuitState::Open
}

///|
/// Provider fallback chain.
/// Each provider is tried in order until one succeeds.
pub struct FallbackChain {
  providers : Array[LLMProviderHandle]
  breaker : CircuitBreaker
}

///|
pub fn FallbackChain::new(
  providers : Array[LLMProviderHandle],
) -> FallbackChain {
  { providers, breaker: CircuitBreaker::new(3) }
}

///|
pub fn FallbackChain::new_with_breaker(
  providers : Array[LLMProviderHandle],
  breaker : CircuitBreaker,
) -> FallbackChain {
  { providers, breaker }
}

///|
/// Try each provider in order. Returns the first successful response.
pub fn FallbackChain::chat(
  self : FallbackChain,
  messages : Array[ChatMessage],
  tools : Array[ChatToolDef]?,
) -> LLMResponse {
  if self.breaker.is_open() {
    return LLMResponse::{
      content: "[circuit breaker open: too many failures]",
      tool_calls: None,
      finish_reason: "error",
    }
  }
  for i = 0; i < self.providers.length(); i = i + 1 {
    let provider = self.providers[i]
    // Use try-catch for sync calls; async errors would need a different pattern
    let resp = provider.chat(messages, tools)
    if resp.finish_reason != "error" {
      self.breaker.record_success()
      return resp
    }
  }
  self.breaker.record_failure()
  LLMResponse::{
    content: "[all providers failed]",
    tool_calls: None,
    finish_reason: "error",
  }
}

///|
/// Convenience: wrap providers into a single handle with fallback.
pub fn create_fallback_provider(
  providers : Array[LLMProviderHandle],
) -> LLMProviderHandle {
  let chain = FallbackChain::new(providers)
  let config = providers[0].config()
  LLMProviderHandle::{
    config_fn: fn() { config },
    chat_fn: fn(messages, tools) { chain.chat(messages, tools) },
  }
}
