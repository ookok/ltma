///|
/// Background scheduler — scheduled/cron-like agent execution.

///|
/// ScheduleSpec — defines when a job should run.
pub struct ScheduleSpec {
  interval_ms : Int
  repeat : Bool
  max_runs : Int
}

///|
pub fn ScheduleSpec::once() -> ScheduleSpec {
  { interval_ms: 0, repeat: false, max_runs: 1 }
}

///|
pub fn ScheduleSpec::periodic(interval_ms : Int) -> ScheduleSpec {
  { interval_ms, repeat: true, max_runs: -1 }
}

///|
pub fn ScheduleSpec::limited(interval_ms : Int, max_runs : Int) -> ScheduleSpec {
  { interval_ms, repeat: true, max_runs }
}

///|
/// ScheduledJob — a job to be executed by the scheduler.
pub struct ScheduledJob {
  name : String
  spec : ScheduleSpec
  agent_name : String
  input : String
  mut run_count : Int
  enabled : Bool
}

///|
pub fn ScheduledJob::new(
  name : String,
  spec : ScheduleSpec,
  agent_name : String,
  input : String,
) -> ScheduledJob {
  { name, spec, agent_name, input, run_count: 0, enabled: true }
}

///|
/// Scheduler — runs scheduled jobs.
pub struct Scheduler {
  jobs : Map[String, ScheduledJob]
  host : AgentHost
}

///|
pub fn Scheduler::new(host : AgentHost) -> Scheduler {
  { jobs: Map([]), host }
}

///|
pub fn Scheduler::add_job(self : Scheduler, job : ScheduledJob) -> Unit {
  self.jobs[job.name] = job
}

///|
pub fn Scheduler::remove_job(self : Scheduler, name : String) -> Unit {
  self.jobs.remove(name)
}

///|
pub fn Scheduler::tick(self : Scheduler) -> Unit {
  for name, job in self.jobs {
    if !job.enabled {
      continue
    }
    if job.spec.max_runs >= 0 && job.run_count >= job.spec.max_runs {
      continue
    }
    let id = @core.AgentId::create(job.agent_name, "0.1.0", "livingtree/ltma")
    match self.host.activate(id) {
      Some(token) => {
        let _ = token.call(@core.Message::text(job.input))
        token.shutdown()
        job.run_count = job.run_count + 1
      }
      None => ()
    }
  }
}

///|
pub fn Scheduler::run_count(self : Scheduler) -> Int {
  let mut total = 0
  for _, job in self.jobs {
    total = total + job.run_count
  }
  total
}

///|
pub fn Scheduler::job_count(self : Scheduler) -> Int {
  self.jobs.length()
}
