///|
/// Health Check — liveness and readiness probes for agents.

///|
/// HealthStatus — result of a health probe.
pub enum HealthStatus {
  Healthy
  Degraded(String)
  Unhealthy(String)
}

///|
/// HealthProbe — a function that checks agent health.
pub type HealthProbe = () -> HealthStatus

///|
/// HealthCheck — configurable health check with probes.
pub struct HealthCheck {
  name : String
  probes : Array[HealthProbe]
  mut healthy : Bool
  mut last_error : String
}

///|
pub fn HealthCheck::new(name : String) -> HealthCheck {
  { name, probes: [], healthy: true, last_error: "" }
}

///|
pub fn HealthCheck::add_probe(self : HealthCheck, probe : HealthProbe) -> Unit {
  self.probes.push(probe)
}

///|
pub fn HealthCheck::check(self : HealthCheck) -> HealthStatus {
  for probe in self.probes {
    let result = probe()
    match result {
      HealthStatus::Healthy => continue
      HealthStatus::Degraded(msg) => {
        self.healthy = false
        self.last_error = msg
        return result
      }
      HealthStatus::Unhealthy(msg) => {
        self.healthy = false
        self.last_error = msg
        return result
      }
    }
  }
  self.healthy = true
  self.last_error = ""
  HealthStatus::Healthy
}

///|
pub fn HealthCheck::is_healthy(self : HealthCheck) -> Bool {
  self.healthy
}

///|
pub fn HealthCheck::last_error(self : HealthCheck) -> String {
  self.last_error
}

///|
/// HealthRegistry — manages health checks for multiple components.
pub struct HealthRegistry {
  checks : Map[String, HealthCheck]
}

///|
pub fn HealthRegistry::new() -> HealthRegistry {
  { checks: Map([]) }
}

///|
pub fn HealthRegistry::register(
  self : HealthRegistry,
  check : HealthCheck,
) -> Unit {
  self.checks[check.name] = check
}

///|
pub fn HealthRegistry::run_all(
  self : HealthRegistry,
) -> Array[(String, HealthStatus)] {
  let result : Array[(String, HealthStatus)] = []
  for name, check in self.checks {
    result.push((name, check.check()))
  }
  result
}

///|
pub fn HealthRegistry::overall(self : HealthRegistry) -> HealthStatus {
  for _, check in self.checks {
    let status = check.check()
    match status {
      HealthStatus::Unhealthy(_) => return status
      _ => continue
    }
  }
  HealthStatus::Healthy
}
