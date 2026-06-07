///|
/// Rate Limiter — API call frequency control with backoff and retry.

///|
/// RateLimitConfig — configuration for rate limiting.
pub struct RateLimitConfig {
  max_requests_per_minute : Int
  max_concurrent : Int
  retry_base_ms : Int
  retry_max_ms : Int
  max_retries : Int
}

///|
pub fn RateLimitConfig::default() -> RateLimitConfig {
  {
    max_requests_per_minute: 60,
    max_concurrent: 10,
    retry_base_ms: 1000,
    retry_max_ms: 60000,
    max_retries: 3,
  }
}

///|
/// RateLimiterState — tracks per-provider rate limit state.
pub struct RateLimiterState {
  config : RateLimitConfig
  request_timestamps : Array[Int]
  mut current_concurrent : Int
}

///|
pub fn RateLimiterState::new(config : RateLimitConfig) -> RateLimiterState {
  { config, request_timestamps: [], current_concurrent: 0 }
}

///|
pub fn RateLimiterState::acquire(self : RateLimiterState) -> Bool {
  let now = 0
  self.prune(now)
  if self.current_concurrent >= self.config.max_concurrent {
    return false
  }
  if self.request_timestamps.length() >= self.config.max_requests_per_minute {
    return false
  }
  self.current_concurrent = self.current_concurrent + 1
  self.request_timestamps.push(now)
  true
}

///|
pub fn RateLimiterState::release(self : RateLimiterState) -> Unit {
  if self.current_concurrent > 0 {
    self.current_concurrent = self.current_concurrent - 1
  }
}

///|
pub fn RateLimiterState::backoff_delay(
  self : RateLimiterState,
  attempt : Int,
) -> Int {
  let multiplier = pow2(attempt)
  let delay = self.config.retry_base_ms * multiplier
  if delay > self.config.retry_max_ms {
    self.config.retry_max_ms
  } else {
    delay
  }
}

///|
fn pow2(n : Int) -> Int {
  let mut result = 1
  for i = 0; i < n; i = i + 1 {
    result = result * 2
  }
  result
}

///|
pub fn RateLimiterState::can_retry(
  self : RateLimiterState,
  attempt : Int,
) -> Bool {
  attempt < self.config.max_retries
}

///|
fn RateLimiterState::prune(self : RateLimiterState, now : Int) -> Unit {
  let cutoff = now - 60000
  let mut i = 0
  while i < self.request_timestamps.length() {
    if self.request_timestamps[i] < cutoff {
      let _ = self.request_timestamps.remove(i)
    } else {
      i = i + 1
    }
  }
}
