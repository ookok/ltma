///|
/// OpenTelemetry integration — trace export stub.

///|
/// Trace severity levels.
pub enum OtelLevel {
  Trace
  Debug
  Info
  Warn
  Error
}

///|
/// Export a span to OpenTelemetry-compatible format.
pub fn export_span(
  trace_id : String,
  span_id : String,
  parent_id : String?,
  name : String,
  duration_ns : Int64,
) -> Unit {
  // OTLP export would go here (HTTP/gRPC to collector)
  // For now, just log to console
  let parent = match parent_id {
    Some(p) => " parent=" + p
    None => ""
  }
  println(
    "[otel] trace=" +
    trace_id +
    " span=" +
    span_id +
    parent +
    " name=" +
    name +
    " duration_ns=" +
    duration_ns.to_string(),
  )
}
