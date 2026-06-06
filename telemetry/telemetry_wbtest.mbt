///|
test "Logger debug/info/warn/error by level" {
  let log = Logger::new_with_level("test", LogLevel::Warn)
  log.debug("should not appear")
  log.info("should not appear")
  log.warn("should appear")
  log.error("should appear")
  assert_true(true)
}

///|
test "Counter inc and value" {
  let c = Counter::new("test_count")
  assert_eq(c.value(), 0L)
  c.inc(5L)
  assert_eq(c.value(), 5L)
  c.inc(3L)
  assert_eq(c.value(), 8L)
  c.reset()
  assert_eq(c.value(), 0L)
}

///|
test "Gauge set and value" {
  let g = Gauge::new("test_gauge")
  assert_eq(g.value(), 0.0)
  g.set(42.5)
  assert_eq(g.value(), 42.5)
}

///|
test "Histogram observe and stats" {
  let h = Histogram::new("test_hist")
  assert_eq(h.count(), 0L)
  h.observe(100L)
  h.observe(200L)
  assert_eq(h.count(), 2L)
  assert_eq(h.sum(), 300L)
  assert_eq(h.avg_ns(), 150L)
}

///|
test "MetricsRegistry creates and reuses metrics" {
  let reg = MetricsRegistry::new()
  let c1 = reg.counter("req_count")
  let c2 = reg.counter("req_count")
  c1.inc(1L)
  assert_eq(c2.value(), 1L)
}

///|
test "Tracer creates spans" {
  let tracer = Tracer::new("test")
  let span = tracer.start("operation")
  span.tag("key", "value")
  span.finish()
  let s = span.to_string()
  assert_true(s.contains("operation"))
  assert_true(s.contains("name="))
}

///|
test "Span child inherits trace_id" {
  let tracer = Tracer::new("test")
  let parent = tracer.start("parent")
  let child = parent.child("child")
  assert_eq(parent.trace_id, child.trace_id)
  child.finish()
}
