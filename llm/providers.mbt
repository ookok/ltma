///|
/// Provider registry — data-driven, supports any OpenAI-compatible API.

///|
/// Provider metadata.
pub struct ProviderInfo {
  name : String
  label : String
  base_url : String
  models : Array[String]
}

///|
pub fn ProviderInfo::new(
  name : String,
  label : String,
  base_url : String,
  models : Array[String],
) -> ProviderInfo {
  { name, label, base_url, models }
}

///|
/// Build a config for any provider + model.
pub fn make_config(
  base_url : String,
  model : String,
  api_key : String,
) -> LLMConfig {
  { api_key, model, api_url: base_url, max_tokens: 4096, temperature: 0.7 }
}

///|
/// Create an async provider from a config.
pub fn create_async_provider(config : LLMConfig) -> AsyncLLMProviderHandle {
  create_async_openai_provider(config)
}

///|
/// All supported providers.
pub fn all_providers() -> Array[ProviderInfo] {
  [
    // === Chinese Providers ===
    ProviderInfo::new("deepseek", "DeepSeek", "https://api.deepseek.com/v1", [
      "deepseek-chat", "deepseek-reasoner",
    ]),
    ProviderInfo::new(
      "zhipu",
      "智谱GLM",
      "https://open.bigmodel.cn/api/paas/v4",
      ["glm-4-plus", "glm-4-0520", "glm-4-air", "glm-4-flash"],
    ),
    ProviderInfo::new(
      "kimi",
      "Kimi/月之暗面",
      "https://api.moonshot.cn/v1",
      ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"],
    ),
    ProviderInfo::new(
      "qwen",
      "Qwen/通义千问",
      "https://dashscope.aliyuncs.com/compatible-mode/v1",
      ["qwen-plus", "qwen-max", "qwen-turbo", "qwen-long"],
    ),
    ProviderInfo::new("minimax", "MiniMax", "https://api.minimax.chat/v1", [
      "minimax-text-01", "minimax-abab6.5",
    ]),
    ProviderInfo::new(
      "siliconflow",
      "硅基流动",
      "https://api.siliconflow.cn/v1",
      [
        "Pro/deepseek-ai/DeepSeek-V3", "Pro/deepseek-ai/DeepSeek-R1", "Qwen/Qwen2.5-72B-Instruct",
        "THUDM/glm-4-9b-chat",
      ],
    ),
    ProviderInfo::new("stepfun", "阶跃星辰", "https://api.stepfun.com/v1", [
      "step-1-8k", "step-1-32k", "step-1-flash",
    ]),
    ProviderInfo::new("mimo", "Mimo", "https://api.mimo.ai/v1", [
      "mimo-1", "mimo-plus",
    ]),
    ProviderInfo::new("loogcat", "LoogCat", "https://api.loogcat.com/v1", [
      "lc-1", "lc-plus",
    ]),
    ProviderInfo::new(
      "baidu",
      "百度文心",
      "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat",
      ["ernie-4.0-8k", "ernie-3.5-8k", "ernie-speed"],
    ),
    ProviderInfo::new(
      "spark",
      "讯飞星火",
      "https://spark-api.xf-yun.com/v4.0/chat",
      ["spark-4.0", "spark-3.5", "spark-3.0"],
    ),
    ProviderInfo::new(
      "sensetime",
      "商汤日日新",
      "https://api.senseapi.cn/v1",
      ["SenseChat-5", "SenseChat-4"],
    ),
    // === International ===
    ProviderInfo::new("openai", "OpenAI", "https://api.openai.com/v1", [
      "gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo",
    ]),
    ProviderInfo::new(
      "anthropic",
      "Anthropic",
      "https://api.anthropic.com/v1",
      ["claude-3-5-sonnet-latest", "claude-3-opus-latest"],
    ),
    ProviderInfo::new(
      "google",
      "Google Gemini",
      "https://generativelanguage.googleapis.com/v1beta/openai",
      ["gemini-2.0-flash", "gemini-2.0-pro"],
    ),
  ]
}

///|
/// Find a provider by name (case-insensitive).
pub fn find_provider(name : String) -> ProviderInfo? {
  let lower = name.to_lower()
  for p in all_providers() {
    if p.name == lower {
      return Some(p)
    }
  }
  None
}

///|
/// Get the default model for a provider.
pub fn default_model(name : String) -> String? {
  match find_provider(name) {
    Some(p) => if p.models.length() > 0 { Some(p.models[0]) } else { None }
    None => None
  }
}

///|
/// Create a provider by name + model + api_key.
/// If model is empty, uses the provider's default model.
pub fn create_provider(
  provider_name : String,
  model : String,
  api_key : String,
) -> AsyncLLMProviderHandle? {
  match find_provider(provider_name) {
    Some(info) => {
      let m = if model != "" { model } else { info.models[0] }
      let config = make_config(info.base_url, m, api_key)
      Some(create_async_openai_provider(config))
    }
    None => None
  }
}

///|
/// Quick-start: provider name + api key, uses default model.
pub fn quick_provider(
  provider_name : String,
  api_key : String,
) -> AsyncLLMProviderHandle? {
  create_provider(provider_name, "", api_key)
}

///|
/// List all provider names.
pub fn list_providers() -> String {
  let mut result = ""
  for p in all_providers() {
    result = result + p.name + "  — " + p.label + "\n"
    result = result + "       " + p.base_url + "\n"
    result = result + "       models: "
    for i = 0; i < p.models.length(); i = i + 1 {
      if i > 0 {
        result = result + ", "
      }
      result = result + p.models[i]
    }
    result = result + "\n"
  }
  result
}
