///|
/// Metrics — counters, gauges, histograms, and registry for observability.

///|
/// Counter — a monotonically increasing counter.
pub struct Counter {
  name : String
  mut val : Int64
}

///|
pub fn Counter::new(name : String) -> Counter {
  { name, val: 0L }
}

///|
pub fn Counter::inc(self : Counter, delta : Int64) -> Unit {
  self.val = self.val + delta
}

///|
pub fn Counter::value(self : Counter) -> Int64 {
  self.val
}

///|
pub fn Counter::reset(self : Counter) -> Unit {
  self.val = 0L
}

///|
/// Gauge — a numeric value that can go up and down.
pub struct Gauge {
  name : String
  mut val : Double
}

///|
pub fn Gauge::new(name : String) -> Gauge {
  { name, val: 0.0 }
}

///|
pub fn Gauge::set(self : Gauge, v : Double) -> Unit {
  self.val = v
}

///|
pub fn Gauge::value(self : Gauge) -> Double {
  self.val
}

///|
/// Histogram — tracks distribution of values.
pub struct Histogram {
  name : String
  mut count_val : Int64
  mut sum_val : Int64
}

///|
pub fn Histogram::new(name : String) -> Histogram {
  { name, count_val: 0L, sum_val: 0L }
}

///|
pub fn Histogram::observe(self : Histogram, val : Int64) -> Unit {
  self.count_val = self.count_val + 1L
  self.sum_val = self.sum_val + val
}

///|
pub fn Histogram::count(self : Histogram) -> Int64 {
  self.count_val
}

///|
pub fn Histogram::sum(self : Histogram) -> Int64 {
  self.sum_val
}

///|
pub fn Histogram::avg_ns(self : Histogram) -> Int64 {
  if self.count_val == 0L {
    0L
  } else {
    self.sum_val / self.count_val
  }
}

///|
/// MetricSample — a snapshot of a metric at a point in time.
pub struct MetricSample {
  name : String
  kind : MetricKind
  value : Double
  labels : Map[String, String]
  timestamp : Int
}

///|
pub fn MetricSample::new(
  name : String,
  kind : MetricKind,
  value : Double,
  labels : Map[String, String],
  timestamp : Int,
) -> MetricSample {
  { name, kind, value, labels, timestamp }
}

///|
pub enum MetricKind {
  Counter
  Gauge
  Histogram
}

///|
/// MetricsRegistry — creates and caches metric instances by name.
pub struct MetricsRegistry {
  counters : Map[String, Counter]
  gauges : Map[String, Gauge]
  histograms : Map[String, Histogram]
}

///|
pub fn MetricsRegistry::new() -> MetricsRegistry {
  { counters: Map([]), gauges: Map([]), histograms: Map([]) }
}

///|
pub fn MetricsRegistry::counter(
  self : MetricsRegistry,
  name : String,
) -> Counter {
  match self.counters.get(name) {
    Some(c) => c
    None => {
      let c = Counter::new(name)
      self.counters[name] = c
      c
    }
  }
}

///|
pub fn MetricsRegistry::gauge(self : MetricsRegistry, name : String) -> Gauge {
  match self.gauges.get(name) {
    Some(g) => g
    None => {
      let g = Gauge::new(name)
      self.gauges[name] = g
      g
    }
  }
}

///|
pub fn MetricsRegistry::histogram(
  self : MetricsRegistry,
  name : String,
) -> Histogram {
  match self.histograms.get(name) {
    Some(h) => h
    None => {
      let h = Histogram::new(name)
      self.histograms[name] = h
      h
    }
  }
}

///|
/// Track LLM API call metrics.
pub fn track_llm_call(
  registry : MetricsRegistry,
  provider : String,
  duration_ms : Int,
  tokens_in : Int,
  tokens_out : Int,
) -> Unit {
  let calls = registry.counter("llm.calls.total")
  calls.inc(1L)
  let in_tokens = registry.counter("llm.tokens.in")
  in_tokens.inc(tokens_in.to_int64())
  let out_tokens = registry.counter("llm.tokens.out")
  out_tokens.inc(tokens_out.to_int64())
  let prov = registry.counter("llm.calls." + provider)
  prov.inc(1L)
}
