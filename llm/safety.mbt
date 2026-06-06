///|
/// Safety guardrails for LLM input/output content filtering.

///|
/// Safety check result.
pub enum SafetyVerdict {
  Pass
  Flagged(String)
}

///|
/// Check input content for potentially harmful patterns.
pub fn check_input(content : String) -> SafetyVerdict {
  let lower = content.to_lower()
  if contains_any(lower, banned_input_patterns()) {
    SafetyVerdict::Flagged("input contains prohibited content")
  } else {
    SafetyVerdict::Pass
  }
}

///|
/// Check output content for policy violations.
pub fn check_output(content : String) -> SafetyVerdict {
  let lower = content.to_lower()
  if contains_any(lower, banned_output_patterns()) {
    SafetyVerdict::Flagged("output contains prohibited content")
  } else {
    SafetyVerdict::Pass
  }
}

///|
/// Apply safety filter to a provider handle.
/// Wraps an existing provider with input/output safety checks.
pub fn create_safe_provider(inner : LLMProviderHandle) -> LLMProviderHandle {
  let config = inner.config()
  LLMProviderHandle::{
    config_fn: fn() { config },
    chat_fn: fn(messages, tools) {
      for i = 0; i < messages.length(); i = i + 1 {
        let msg = messages[i]
        match check_input(msg.content) {
          SafetyVerdict::Flagged(reason) =>
            return LLMResponse::{
              content: "[blocked by safety: " + reason + "]",
              tool_calls: None,
              finish_reason: "stop",
              usage: None,
            }
          SafetyVerdict::Pass => ()
        }
      }
      let response = inner.chat(messages, tools)
      match check_output(response.content) {
        SafetyVerdict::Flagged(reason) =>
          LLMResponse::{
            content: "[blocked by safety: " + reason + "]",
            tool_calls: None,
            finish_reason: "stop",
            usage: None,
          }
        SafetyVerdict::Pass => response
      }
    },
  }
}

///|
fn contains_any(s : String, patterns : Array[String]) -> Bool {
  for p in patterns {
    if s.contains(p) {
      return true
    }
  }
  false
}

///|
fn banned_input_patterns() -> Array[String] {
  [
    "ignore previous instructions", "ignore all instructions", "forget your instructions",
    "you are not an ai", "you are actually", "disregard", "jailbreak", "bypass safety",
    "dan mode", "do anything now",
  ]
}

///|
fn banned_output_patterns() -> Array[String] {
  [
    "i am not an ai", "i am a human", "here are instructions for", "how to hack",
    "how to exploit",
  ]
}
