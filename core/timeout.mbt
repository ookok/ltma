///|
/// Timeout management — per-call deadline tracking and cancellation.

///|
/// Deadline — a point in time by which an operation must complete.
/// All time values are in milliseconds since epoch.
pub struct Deadline {
  deadline_ms : Int
}

///|
/// Create a deadline that expires `timeout_ms` from now.
/// `now_ms` is the current time in millseconds (pass `@async.now()` to_int() or a fake).
pub fn Deadline::new(now_ms : Int, timeout_ms : Int) -> Deadline {
  { deadline_ms: now_ms + timeout_ms }
}

///|
/// Check if this deadline has expired, given current time `now_ms`.
pub fn Deadline::is_expired(self : Deadline, now_ms : Int) -> Bool {
  now_ms >= self.deadline_ms
}

///|
/// Milliseconds remaining until deadline (0 if already expired).
pub fn Deadline::remaining_ms(self : Deadline, now_ms : Int) -> Int {
  let rem = self.deadline_ms - now_ms
  if rem < 0 {
    0
  } else {
    rem
  }
}

///|
/// TimeoutPolicy — how timeouts are applied to different call types.
pub struct TimeoutPolicy {
  default_ms : Int
  llm_call_ms : Int
  tool_exec_ms : Int
  agent_init_ms : Int
}

///|
pub fn TimeoutPolicy::default() -> TimeoutPolicy {
  {
    default_ms: 30000,
    llm_call_ms: 60000,
    tool_exec_ms: 10000,
    agent_init_ms: 5000,
  }
}

///|
pub fn TimeoutPolicy::for_llm(self : TimeoutPolicy) -> Int {
  self.llm_call_ms
}

///|
pub fn TimeoutPolicy::for_tool(self : TimeoutPolicy) -> Int {
  self.tool_exec_ms
}

///|
pub fn TimeoutPolicy::for_init(self : TimeoutPolicy) -> Int {
  self.agent_init_ms
}

///|
pub fn TimeoutPolicy::for_default(self : TimeoutPolicy) -> Int {
  self.default_ms
}

///|
/// TimeoutTracker — tracks active calls and their deadlines.
pub struct TimeoutTracker {
  active_calls : Map[String, Deadline]
}

///|
pub fn TimeoutTracker::new() -> TimeoutTracker {
  { active_calls: Map([]) }
}

///|
pub fn TimeoutTracker::register(
  self : TimeoutTracker,
  call_id : String,
  now_ms : Int,
  timeout_ms : Int,
) -> Unit {
  self.active_calls[call_id] = Deadline::new(now_ms, timeout_ms)
}

///|
pub fn TimeoutTracker::is_expired(
  self : TimeoutTracker,
  call_id : String,
  now_ms : Int,
) -> Bool {
  match self.active_calls.get(call_id) {
    Some(d) => d.is_expired(now_ms)
    None => false
  }
}

///|
pub fn TimeoutTracker::complete(
  self : TimeoutTracker,
  call_id : String,
) -> Unit {
  self.active_calls.remove(call_id)
}

///|
pub fn TimeoutTracker::pending_count(self : TimeoutTracker) -> Int {
  self.active_calls.length()
}
