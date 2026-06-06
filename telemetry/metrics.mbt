///|
/// Simple metrics collection — counters, gauges, and histograms.

///|
pub struct Counter {
  name : String
  mut value : Int64
}

///|
pub fn Counter::new(name : String) -> Counter {
  { name, value: 0L }
}

///|
pub fn Counter::inc(self : Counter, delta : Int64) -> Unit {
  self.value = self.value + delta
}

///|
pub fn Counter::value(self : Counter) -> Int64 {
  self.value
}

///|
pub fn Counter::reset(self : Counter) -> Unit {
  self.value = 0L
}

///|
pub struct Gauge {
  name : String
  mut value : Double
}

///|
pub fn Gauge::new(name : String) -> Gauge {
  { name, value: 0.0 }
}

///|
pub fn Gauge::set(self : Gauge, v : Double) -> Unit {
  self.value = v
}

///|
pub fn Gauge::value(self : Gauge) -> Double {
  self.value
}

///|
pub struct Histogram {
  name : String
  buckets : Map[Int64, Int64]
  mut count : Int64
  mut sum : Int64
}

///|
pub fn Histogram::new(name : String) -> Histogram {
  { name, buckets: Map([]), count: 0L, sum: 0L }
}

///|
pub fn Histogram::observe(self : Histogram, value_ns : Int64) -> Unit {
  self.count = self.count + 1L
  self.sum = self.sum + value_ns
  // Place into power-of-2 bucket
  let mut bucket = 1L
  while bucket < value_ns {
    bucket = bucket * 2L
  }
  let current = self.buckets.get(bucket).unwrap_or(0L)
  self.buckets[bucket] = current + 1L
}

///|
pub fn Histogram::count(self : Histogram) -> Int64 {
  self.count
}

///|
pub fn Histogram::sum(self : Histogram) -> Int64 {
  self.sum
}

///|
pub fn Histogram::avg_ns(self : Histogram) -> Int64 {
  if self.count > 0L {
    self.sum / self.count
  } else {
    0L
  }
}

///|
/// Metrics registry — central store for all metrics.
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
pub fn MetricsRegistry::snapshot(self : MetricsRegistry) -> String {
  let mut result = ""
  for name, c in self.counters {
    result = result + "counter " + name + " " + c.value().to_string() + "\n"
  }
  for name, g in self.gauges {
    result = result + "gauge " + name + " " + g.value().to_string() + "\n"
  }
  for name, h in self.histograms {
    result = result +
      "histogram " +
      name +
      " count=" +
      h.count().to_string() +
      " sum=" +
      h.sum().to_string() +
      " avg=" +
      h.avg_ns().to_string() +
      "\n"
  }
  result
}
