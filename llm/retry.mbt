///|
/// Retry + rate limiting wrapper for LLM providers.

///|
/// Retry configuration.
pub struct RetryConfig {
  max_retries : Int
  base_delay_ms : Int
  max_delay_ms : Int
}

///|
pub fn RetryConfig::default() -> RetryConfig {
  { max_retries: 3, base_delay_ms: 1000, max_delay_ms: 30000 }
}

///|
/// Rate limiter — simple token bucket.
pub struct RateLimiter {
  mut tokens : Int
  max_tokens : Int
  refill_rate : Int
  refill_interval_ms : Int
  mut last_refill_ms : Int64
}

///|
pub fn RateLimiter::new(max_tokens : Int, refill_per_sec : Int) -> RateLimiter {
  {
    tokens: max_tokens,
    max_tokens,
    refill_rate: refill_per_sec,
    refill_interval_ms: 1000,
    last_refill_ms: 0L,
  }
}

///|
pub fn RateLimiter::acquire(self : RateLimiter) -> Bool {
  let now = @async.now()
  let elapsed = now - self.last_refill_ms
  if elapsed > 1000L {
    let add = (elapsed / 1000L).to_int() * self.refill_rate
    self.tokens = (self.tokens + add).min(self.max_tokens)
    self.last_refill_ms = now
  }
  if self.tokens > 0 {
    self.tokens = self.tokens - 1
    true
  } else {
    false
  }
}

///|
/// Wrap an async provider with retry logic.
pub fn with_retry(
  inner : AsyncLLMProviderHandle,
  config : RetryConfig,
) -> AsyncLLMProviderHandle {
  let cfg = inner.config()
  AsyncLLMProviderHandle::{
    config_fn: fn() { cfg },
    chat_fn: async fn(messages, tools) {
      let mut last_error = ""
      for i = 0; i <= config.max_retries; i = i + 1 {
        if i > 0 {
          let delay = (config.base_delay_ms * (1 << (i - 1))).min(
            config.max_delay_ms,
          )
          @async.sleep(delay)
        }
        let resp = inner.chat(messages, tools)
        if resp.finish_reason != "error" {
          return resp
        }
        last_error = resp.content
      }
      LLMResponse::{
        content: "retry failed after " +
        config.max_retries.to_string() +
        " attempts: " +
        last_error,
        tool_calls: None,
        finish_reason: "error",
        usage: None,
      }
    },
  }
}

///|
/// Wrap a provider with rate limiting.
pub fn with_rate_limit(
  inner : AsyncLLMProviderHandle,
  limiter : RateLimiter,
) -> AsyncLLMProviderHandle {
  let cfg = inner.config()
  AsyncLLMProviderHandle::{
    config_fn: fn() { cfg },
    chat_fn: async fn(messages, tools) {
      if !limiter.acquire() {
        @async.sleep(1000)
      }
      inner.chat(messages, tools)
    },
  }
}
