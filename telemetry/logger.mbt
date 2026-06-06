///|
/// Structured logger with severity levels and JSON output.

///|
pub enum LogLevel {
  Debug
  Info
  Warn
  Error
}

///|
fn level_name(level : LogLevel) -> String {
  match level {
    LogLevel::Debug => "DEBUG"
    LogLevel::Info => "INFO"
    LogLevel::Warn => "WARN"
    LogLevel::Error => "ERROR"
  }
}

///|
pub struct Logger {
  name : String
  min_level : LogLevel
}

///|
pub fn Logger::new(name : String) -> Logger {
  { name, min_level: LogLevel::Info }
}

///|
pub fn Logger::new_with_level(name : String, level : LogLevel) -> Logger {
  { name, min_level: level }
}

///|
fn Logger::should_log(self : Logger, level : LogLevel) -> Bool {
  let order = match level {
    LogLevel::Debug => 0
    LogLevel::Info => 1
    LogLevel::Warn => 2
    LogLevel::Error => 3
  }
  let min_order = match self.min_level {
    LogLevel::Debug => 0
    LogLevel::Info => 1
    LogLevel::Warn => 2
    LogLevel::Error => 3
  }
  order >= min_order
}

///|
pub fn Logger::debug(self : Logger, msg : String) -> Unit {
  if self.should_log(LogLevel::Debug) {
    self.write(LogLevel::Debug, msg, Map([]))
  }
}

///|
pub fn Logger::info(self : Logger, msg : String) -> Unit {
  if self.should_log(LogLevel::Info) {
    self.write(LogLevel::Info, msg, Map([]))
  }
}

///|
pub fn Logger::warn(self : Logger, msg : String) -> Unit {
  if self.should_log(LogLevel::Warn) {
    self.write(LogLevel::Warn, msg, Map([]))
  }
}

///|
pub fn Logger::error(self : Logger, msg : String) -> Unit {
  if self.should_log(LogLevel::Error) {
    self.write(LogLevel::Error, msg, Map([]))
  }
}

///|
pub fn Logger::debug_with(
  self : Logger,
  msg : String,
  fields : Map[String, String],
) -> Unit {
  if self.should_log(LogLevel::Debug) {
    self.write(LogLevel::Debug, msg, fields)
  }
}

///|
pub fn Logger::info_with(
  self : Logger,
  msg : String,
  fields : Map[String, String],
) -> Unit {
  if self.should_log(LogLevel::Info) {
    self.write(LogLevel::Info, msg, fields)
  }
}

///|
pub fn Logger::warn_with(
  self : Logger,
  msg : String,
  fields : Map[String, String],
) -> Unit {
  if self.should_log(LogLevel::Warn) {
    self.write(LogLevel::Warn, msg, fields)
  }
}

///|
pub fn Logger::error_with(
  self : Logger,
  msg : String,
  fields : Map[String, String],
) -> Unit {
  if self.should_log(LogLevel::Error) {
    self.write(LogLevel::Error, msg, fields)
  }
}

///|
fn Logger::write(
  self : Logger,
  level : LogLevel,
  msg : String,
  fields : Map[String, String],
) -> Unit {
  let mut parts = "["
  parts = parts + level_name(level)
  parts = parts + "] "
  parts = parts + self.name
  parts = parts + ": "
  parts = parts + msg
  for k, v in fields {
    parts = parts + " "
    parts = parts + k
    parts = parts + "="
    parts = parts + v
  }
  println(parts)
}

///|
/// Root logger for the application.
pub fn root_logger() -> Logger {
  Logger::new("ltma")
}
