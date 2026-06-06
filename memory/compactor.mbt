///|
/// Context compactor — manages context window size by summarizing older messages.

///|
pub struct ContextCompactor {
  max_messages : Int
}

///|
pub fn ContextCompactor::new(max_messages : Int) -> ContextCompactor {
  { max_messages, }
}

///|
pub fn ContextCompactor::compact(
  self : ContextCompactor,
  messages : Array[String],
) -> Array[String] {
  if messages.length() <= self.max_messages {
    messages
  } else {
    // Keep the last N messages, summarize earlier ones into one
    let keep = self.max_messages - 1
    let summary = "[... \{messages.length() - keep} earlier messages summarized ...]"
    let result : Array[String] = [summary]
    for i = messages.length() - keep; i < messages.length(); i = i + 1 {
      result.push(messages[i])
    }
    result
  }
}

///|
pub fn ContextCompactor::summarize(
  _self : ContextCompactor,
  messages : Array[String],
) -> String {
  if messages.length() == 0 {
    return ""
  }
  let total_len = messages.length()
  let mut char_count = 0
  for i = 0; i < total_len; i = i + 1 {
    char_count = char_count + messages[i].length()
  }
  "Session: \{total_len} messages, \{char_count} chars"
}
