///|
/// Random tool — random numbers and strings.

///|
pub fn random_number(max : Int) -> Int {
  // Simple pseudo-random using timestamp
  let ts = get_tick()
  (ts % max).abs()
}

///|
fn get_tick() -> Int {
  // Placeholder — use system tick count in production
  42
}

///|
pub fn random_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create("random", "Generate a random number (0 to max-1)", "{type:object,properties:{max:{type:int}}}", false)
}
