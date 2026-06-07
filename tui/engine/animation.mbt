///|
/// Spinner (braille) and spinner helpers.
pub type Spinner = Array[String]

///|
pub fn default_spinner() -> Spinner {
  ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
}

///|
pub fn spinner_char(spinner : Spinner, frame : Int) -> String {
  spinner[frame % spinner.length()]
}
