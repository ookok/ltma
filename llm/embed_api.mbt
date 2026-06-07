///|
/// Remote embedding API — calls OpenAI-compatible embedding endpoints.

///|
/// Get an embedding vector from an OpenAI-compatible API.
pub async fn get_embedding(
  api_key : String,
  model : String,
  input_text : String,
  api_url : String,
) -> Array[Double]? {
  let body = "{\"input\":\"" + input_text + "\",\"model\":\"" + model + "\"}"
  let headers = Map([
    ("Content-Type", "application/json"),
    ("Authorization", "Bearer " + api_key),
  ])
  let (resp, data) = @async_http.post(api_url, body, headers~)
  if resp.code != 200 {
    return None
  }
  let text = data.text()
  parse_embedding_response(text)
}

///|
/// Parse an embedding from the OpenAI embedding response format.
pub fn parse_embedding_response(body : String) -> Array[Double]? {
  let search = "\"embedding\":["
  match body.find(search) {
    Some(start) => {
      let after = body.sub(start=start + search.length())
      let closing = after.find("]")
      match closing {
        Some(end) => {
          let nums_str = after.sub(start=0, end~).to_owned()
          let parts = nums_str.split(",")
          let result : Array[Double] = []
          for p in parts {
            let trimmed = p.trim().to_owned()
            if trimmed != "" {
              let val = @string.parse_double(trimmed) catch { _ => 0.0 }
              result.push(val)
            }
          }
          Some(result)
        }
        None => None
      }
    }
    None => None
  }
}

///|
/// Default embedding config for OpenAI.
pub fn openai_embedding_config(api_key : String) -> (String, String, String) {
  (api_key, "text-embedding-3-small", "https://api.openai.com/v1/embeddings")
}
