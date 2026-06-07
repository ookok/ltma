///|
/// Bulkhead — concurrent call isolation for agents and LLM providers.

///|
/// BulkheadConfig — max concurrent calls and queue size.
pub struct BulkheadConfig {
  max_concurrent : Int
  max_queue : Int
}

///|
pub fn BulkheadConfig::default() -> BulkheadConfig {
  { max_concurrent: 10, max_queue: 100 }
}

///|
pub fn BulkheadConfig::restrictive() -> BulkheadConfig {
  { max_concurrent: 3, max_queue: 20 }
}

///|
/// Bulkhead — per-resource concurrency limiter.
pub struct Bulkhead {
  name : String
  config : BulkheadConfig
  mut active : Int
  mut queued : Int
  mut rejected : Int
}

///|
pub fn Bulkhead::new(name : String, config : BulkheadConfig) -> Bulkhead {
  { name, config, active: 0, queued: 0, rejected: 0 }
}

///|
pub fn Bulkhead::try_acquire(self : Bulkhead) -> Bool {
  if self.active < self.config.max_concurrent {
    self.active = self.active + 1
    true
  } else if self.queued < self.config.max_queue {
    self.queued = self.queued + 1
    true
  } else {
    self.rejected = self.rejected + 1
    false
  }
}

///|
pub fn Bulkhead::release(self : Bulkhead) -> Unit {
  if self.active > 0 {
    self.active = self.active - 1
  }
  if self.queued > 0 {
    self.queued = self.queued - 1
  }
}

///|
pub fn Bulkhead::active_count(self : Bulkhead) -> Int {
  self.active
}

///|
pub fn Bulkhead::queued_count(self : Bulkhead) -> Int {
  self.queued
}

///|
pub fn Bulkhead::rejected_count(self : Bulkhead) -> Int {
  self.rejected
}

///|
pub fn Bulkhead::utilization(self : Bulkhead) -> Double {
  if self.config.max_concurrent == 0 {
    0.0
  } else {
    self.active.to_double() / self.config.max_concurrent.to_double()
  }
}

///|
/// BulkheadRegistry — manages bulkheads for multiple resources.
pub struct BulkheadRegistry {
  entries : Map[String, Bulkhead]
}

///|
pub fn BulkheadRegistry::new() -> BulkheadRegistry {
  { entries: Map([]) }
}

///|
pub fn BulkheadRegistry::get_or_create(
  self : BulkheadRegistry,
  name : String,
  config : BulkheadConfig,
) -> Bulkhead {
  match self.entries.get(name) {
    Some(b) => b
    None => {
      let b = Bulkhead::new(name, config)
      self.entries[name] = b
      b
    }
  }
}

///|
pub fn BulkheadRegistry::snapshot(
  self : BulkheadRegistry,
) -> Array[(String, Int, Int, Int)] {
  let result : Array[(String, Int, Int, Int)] = []
  for name, b in self.entries {
    result.push((name, b.active, b.queued, b.rejected))
  }
  result
}
