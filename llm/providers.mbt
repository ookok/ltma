///|
/// Provider registry — create LLM providers by name with just an API key.

///|
/// Supported provider kinds.
pub enum ProviderKind {
  DeepSeek
  Moonshot
  Qwen
  Baidu
  Spark
  OpenAI
}

///|
pub fn ProviderKind::deepseek() -> ProviderKind { ProviderKind::DeepSeek }
pub fn ProviderKind::moonshot() -> ProviderKind { ProviderKind::Moonshot }
pub fn ProviderKind::qwen() -> ProviderKind { ProviderKind::Qwen }
pub fn ProviderKind::baidu() -> ProviderKind { ProviderKind::Baidu }
pub fn ProviderKind::spark() -> ProviderKind { ProviderKind::Spark }
pub fn ProviderKind::openai() -> ProviderKind { ProviderKind::OpenAI }

///|
pub fn provider_name(kind : ProviderKind) -> String {
  match kind {
    ProviderKind::DeepSeek => "DeepSeek"
    ProviderKind::Moonshot => "Moonshot"
    ProviderKind::Qwen => "Qwen"
    ProviderKind::Baidu => "Baidu"
    ProviderKind::Spark => "Spark"
    ProviderKind::OpenAI => "OpenAI"
  }
}

///|
/// Get the default config for a provider kind.
pub fn default_config(kind : ProviderKind, api_key : String) -> LLMConfig {
  match kind {
    ProviderKind::DeepSeek => LLMConfig::deepseek_default(api_key)
    ProviderKind::Moonshot => LLMConfig::moonshot_default(api_key)
    ProviderKind::Qwen => LLMConfig::qwen_default(api_key)
    ProviderKind::Baidu => LLMConfig::baidu_default(api_key)
    ProviderKind::Spark => LLMConfig::spark_default(api_key)
    ProviderKind::OpenAI => LLMConfig::openai_default(api_key)
  }
}

///|
/// Create an async provider by kind.
pub fn create_provider(
  kind : ProviderKind,
  api_key : String,
) -> AsyncLLMProviderHandle {
  let config = default_config(kind, api_key)
  create_async_openai_provider(config)
}

///|
/// Auto-detect provider kind from an API key prefix.
pub fn detect_provider(api_key : String) -> ProviderKind {
  if api_key.has_prefix("sk-") && !api_key.has_prefix("sk-ant") {
    // DeepSeek or OpenAI keys start with "sk-"
    // DeepSeek keys are usually "sk-" + hex, OpenAI are "sk-proj-" or "sk-"
    // Default to DeepSeek for sk- keys (common Chinese usage)
    ProviderKind::DeepSeek
  } else if api_key.has_prefix("sk-ant") {
    ProviderKind::Moonshot
  } else if api_key.has_prefix("sk-moonshot") {
    ProviderKind::Moonshot
  } else if api_key.length() > 20 {
    // Generic long key — default to Qwen
    ProviderKind::Qwen
  } else {
    ProviderKind::OpenAI
  }
}

///|
/// Quick-start: create a provider from just an API key.
/// Detects the provider kind automatically.
pub fn quick_provider(api_key : String) -> AsyncLLMProviderHandle {
  let kind = detect_provider(api_key)
  create_provider(kind, api_key)
}
