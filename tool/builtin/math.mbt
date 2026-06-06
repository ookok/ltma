///|
/// Math tool — evaluate arithmetic expressions.

///|
pub fn math_eval(expression : String) -> String {
  let trimmed = expression.trim().to_owned()
  if trimmed == "" { return "error: empty expression" }
  let parts = trimmed.split(" ")
  let mut total = 0.0
  let mut op = "+"
  let mut first = true
  for p in parts {
    let token = p.trim().to_owned()
    if token == "" { continue }
    if token == "+" || token == "-" || token == "*" || token == "/" {
      op = token
      first = false
    } else {
      let num = try { @string.parse_double(token) } catch { _ => return "error: invalid number '" + token + "'" }
      if first { total = num; first = false }
      else {
        if op == "+" { total = total + num }
        else if op == "-" { total = total - num }
        else if op == "*" { total = total * num }
        else if op == "/" { total = total / num }
      }
    }
  }
  if first { "error: no numbers" } else { total.to_string() }
}

///|
pub fn math_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create("math", "Evaluate a math expression (e.g. '2 + 3')", "{type:object,properties:{expression:{type:string}}}", false)
}
