///|
/// glob tool — find files matching a wildcard pattern.

///|
fn match_glob(pattern : String, name : String) -> Bool {
  let pat = pattern.to_lower()
  let s = name.to_lower()
  let mut pi = 0
  let mut si = 0
  while si < s.length() && pi < pat.length() {
    let pc = pat[pi]
    let sc = s[si]
    if pc == '*' {
      pi = pi + 1
      if pi >= pat.length() { return true }
      while si < s.length() {
        let rest_p = pat.substring(start=pi, end=pat.length())
        let rest_s = s.substring(start=si, end=s.length())
        if match_glob(rest_p, rest_s) { return true }
        si = si + 1
      }
      return false
    } else if pc == '?' || pc == sc {
      pi = pi + 1
      si = si + 1
    } else {
      return false
    }
  }
  pi >= pat.length() && si >= s.length()
}

///|
pub fn glob_tool(pattern : String) -> String {
  // Simple split: find last /
  let sep_idx = try {
    let mut idx = -1
    for i = 0; i < pattern.length(); i = i + 1 {
      if pattern[i] == '/' { idx = i }
    }
    idx
  } catch { _ => -1 }
  let file_pat = if sep_idx >= 0 { pattern.substring(start=sep_idx + 1, end=pattern.length()) } else { pattern }
  let dir = if sep_idx >= 0 { pattern.substring(start=0, end=sep_idx) } else { "." }
  let entries = try { @xfs.read_dir(dir) } catch { _ => return "error reading: " + dir }
  let mut result = ""
  let mut count = 0
  for e in entries {
    if match_glob(file_pat, e) {
      count = count + 1
      if result != "" { result = result + "\n" }
      result = result + dir + "/" + e
    }
  }
  if count == 0 { "no files matching " + pattern } else { result }
}

///|
pub fn glob_tool_json(input : String) -> String {
  let pattern = extract_field(input, "pattern").unwrap_or("*")
  glob_tool(pattern)
}

///|
pub fn glob_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create("glob", "Find files matching a wildcard pattern (e.g. *.mbt)", "{type:object,properties:{pattern:{type:string}}}", false)
}
