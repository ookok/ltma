///|
/// Span-based tracing for distributed request tracking.

///|
pub struct Span {
  name : String
  trace_id : String
  span_id : String
  parent_id : String?
  start_time : Int64
  mut end_time : Int64?
  tags : Map[String, String]
}

///|
pub fn Span::new(name : String, trace_id : String) -> Span {
  {
    name,
    trace_id,
    span_id: generate_id(),
    parent_id: None,
    start_time: now_ns(),
    end_time: None,
    tags: Map([]),
  }
}

///|
pub fn Span::child(self : Span, name : String) -> Span {
  {
    name,
    trace_id: self.trace_id,
    span_id: generate_id(),
    parent_id: Some(self.span_id),
    start_time: now_ns(),
    end_time: None,
    tags: Map([]),
  }
}

///|
pub fn Span::tag(self : Span, key : String, value : String) -> Unit {
  self.tags[key] = value
}

///|
pub fn Span::finish(self : Span) -> Unit {
  self.end_time = Some(now_ns())
}

///|
pub fn Span::duration_ns(self : Span) -> Int64 {
  match self.end_time {
    Some(end) => end - self.start_time
    None => now_ns() - self.start_time
  }
}

///|
pub fn Span::to_string(self : Span) -> String {
  let dur = self.duration_ns()
  "trace=" +
  self.trace_id +
  " span=" +
  self.span_id +
  " name=" +
  self.name +
  " duration_ns=" +
  dur.to_string()
}

///|
pub struct Tracer {
  name : String
}

///|
pub fn Tracer::new(name : String) -> Tracer {
  { name, }
}

///|
pub fn Tracer::start(_self : Tracer, span_name : String) -> Span {
  Span::new(span_name, generate_id())
}

///|
fn generate_id() -> String {
  let ts = now_ns()
  let mut s = ts.to_string()
  while s.length() < 16 {
    s = "0" + s
  }
  s
}

///|
fn now_ns() -> Int64 {
  @async.now() * 1_000_000L
}
