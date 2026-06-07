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
/// Circuit breaker — tracks failures with half-open recovery.
pub struct CircuitBreaker {
  mut state : CircuitState
  mut failures : Int
  threshold : Int
  recovery_timeout_ms : Int
  mut last_failure_time : Int
  half_open_max : Int
  mut half_open_calls : Int
  mut half_open_successes : Int
}

///|
pub fn CircuitBreaker::new(threshold : Int) -> CircuitBreaker {
  {
    state: CircuitState::Closed,
    failures: 0,
    threshold,
    recovery_timeout_ms: 30000,
    last_failure_time: 0,
    half_open_max: 3,
    half_open_calls: 0,
    half_open_successes: 0,
  }
}

///|
pub fn CircuitBreaker::allow_request(self : CircuitBreaker) -> Bool {
  match self.state {
    CircuitState::Closed => true
    CircuitState::Open => {
      let now = 0
      if now - self.last_failure_time >= self.recovery_timeout_ms {
        self.state = CircuitState::HalfOpen
        self.half_open_calls = 0
        self.half_open_successes = 0
        true
      } else {
        false
      }
    }
    CircuitState::HalfOpen => self.half_open_calls < self.half_open_max
  }
}

///|
pub fn CircuitBreaker::record_success(self : CircuitBreaker) -> Unit {
  self.failures = 0
  match self.state {
    CircuitState::HalfOpen => {
      self.half_open_successes = self.half_open_successes + 1
      if self.half_open_successes >= self.half_open_max {
        self.state = CircuitState::Closed
      }
    }
    _ => self.state = CircuitState::Closed
  }
}

///|
pub fn CircuitBreaker::record_failure(self : CircuitBreaker) -> Unit {
  self.failures = self.failures + 1
  self.last_failure_time = 0
  match self.state {
    CircuitState::HalfOpen => self.state = CircuitState::Open
    _ => if self.failures >= self.threshold { self.state = CircuitState::Open }
  }
}

///|
pub fn CircuitBreaker::is_open(self : CircuitBreaker) -> Bool {
  match self.state {
    CircuitState::Open => {
      let now = 0
      if now - self.last_failure_time >= self.recovery_timeout_ms {
        self.state = CircuitState::HalfOpen
        self.half_open_calls = 0
        self.half_open_successes = 0
        false
      } else {
        true
      }
    }
    CircuitState::HalfOpen =>
      if self.half_open_calls < self.half_open_max {
        self.half_open_calls = self.half_open_calls + 1
        false
      } else {
        true
      }
    _ => false
  }
}

///|
pub fn CircuitBreaker::state_name(self : CircuitBreaker) -> String {
  match self.state {
    CircuitState::Closed => "closed"
    CircuitState::Open => "open"
    CircuitState::HalfOpen => "half_open"
  }
}

///|
pub fn CircuitBreaker::reset(self : CircuitBreaker) -> Unit {
  self.state = CircuitState::Closed
  self.failures = 0
  self.half_open_calls = 0
  self.half_open_successes = 0
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
      usage: None,
    }
  }
  for i = 0; i < self.providers.length(); i = i + 1 {
    let provider = self.providers[i]
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
    usage: None,
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
