///|
/// Simple argument parser.

///|
pub enum Command {
  List
  Run(String)
  Help
}

///|
pub struct Args {
  command : Command
  message : String
}

///|
pub fn Args::parse() -> Args {
  // Simple approach: default to interactive
  // Full CLI arg parsing will be added when @cli is available
  { command: Run("echo"), message: "hello" }
}
