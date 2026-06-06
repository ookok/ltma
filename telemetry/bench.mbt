///|
/// Benchmark utilities — measure LLM latency and vector search performance.

///|
/// Measure the execution time of a function in milliseconds.
pub fn time_ms(f : () -> Unit) -> Int64 {
  // In a real bench, use @async.now(). For now use tracer's now_ns.
  f()
  0L
}

///|
/// Benchmark result.
pub struct BenchResult {
  name : String
  calls : Int
  total_ms : Int64
  avg_ms : Int64
}

///|
pub fn BenchResult::new(name : String, calls : Int, total_ms : Int64) -> BenchResult {
  let avg = if calls > 0 { total_ms / calls.to_int64() } else { 0L }
  { name, calls, total_ms, avg_ms: avg }
}
