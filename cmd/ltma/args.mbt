///|
/// Command-line argument parser.

///|
pub enum Command {
  Demo
  Run(String, String)
  Chat
  List
  Help
  Version
}

///|
pub struct Args {
  command : Command
}

///|
pub fn Args::parse() -> Args {
  let raw = @env.args()
  if raw.length() <= 1 {
    { command: Command::Demo }
  } else {
    let cmd = raw[1]
    if cmd == "run" && raw.length() >= 3 {
      let agent = raw[2]
      let msg = if raw.length() >= 4 { raw[3] } else { "" }
      { command: Command::Run(agent, msg) }
    } else if cmd == "chat" {
      { command: Command::Chat }
    } else if cmd == "list" {
      { command: Command::List }
    } else if cmd == "--version" || cmd == "-v" {
      { command: Command::Version }
    } else if cmd == "--help" || cmd == "-h" || cmd == "help" {
      { command: Command::Help }
    } else {
      {
        command: Command::Run(cmd, if raw.length() >= 3 { raw[2] } else { "" }),
      }
    }
  }
}

///|
pub fn print_help() -> Unit {
  println("LTMA — LivingTreeMoonBitAgent v0.1.0")
  println("")
  println("Usage: ltma [command] [args]")
  println("")
  println("Commands:")
  println("  run <agent> [message]   Run an agent with an optional message")
  println("  chat                    Start interactive chat (TUI)")
  println("  list                    List registered agents")
  println("  help, --help, -h        Show this help")
  println("  --version, -v           Show version")
  println("")
  println("Without arguments, runs the full pipeline demo.")
}
