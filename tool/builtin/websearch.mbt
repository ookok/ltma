///|
/// Web search tool — DuckDuckGo Instant Answer API (free, no API key).

///|
pub fn websearch(query : String) -> String {
  let url = "https://api.duckduckgo.com/?q=" + url_encode(query) + "&format=json&no_html=1&skip_disambig=1"
  let mut result = ""
  @async.run_async_main(async fn() {
    let headers = Map([("User-Agent", "LTMA/0.1.0")])
    let (resp, data) = @async_http.get(url, headers=headers)
    if resp.code == 200 {
      result = parse_ddg(data.text())
    } else {
      result = "HTTP error: " + resp.code.to_string()
    }
  })
  result
}

///|
fn parse_ddg(body : String) -> String {
  let mut out = ""
  let abs = extract_field_json(body, "AbstractText")
  let src = extract_field_json(body, "AbstractSource")
  if abs is Some(t) {
    out = out + t + "\n"
  }
  let ans = extract_field_json(body, "Answer")
  if ans is Some(a) { out = out + "Answer: " + a + "\n" }
  let topics = extract_text_array(body, 5)
  for t in topics { out = out + "- " + t + "\n" }
  if out == "" { "no results" } else { out }
}

///|
fn extract_field_json(json : String, field : String) -> String? {
  let search = "\"" + field + "\":\""
  match json.find(search) {
    Some(start) => {
      let after = json.sub(start=start + search.length())
      match after.find("\"") {
        Some(end) => Some(after.sub(start=0, end=end).to_owned())
        None => None
      }
    }
    None => None
  }
}

///|
fn extract_text_array(body : String, max : Int) -> Array[String] {
  let result : Array[String] = []
  let search = "\"Text\":\""
  let mut count = 0
  let mut pos = 0
  while count < max {
    let remaining = body.sub(start=pos)
    match remaining.find(search) {
      Some(start) => {
        let after = remaining.sub(start=start + search.length())
        match after.find("\"") {
          Some(end) => {
            result.push(after.sub(start=0, end=end).to_owned())
            count = count + 1
            pos = pos + start + 1
          }
          None => break
        }
      }
      None => break
    }
  }
  result
}

///|
fn url_encode(s : String) -> String {
  let mut result = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') {
      result = result + c.to_string()
    } else if c == ' ' {
      result = result + "+"
    } else {
      result = result + c.to_string()
    }
  }
  result
}

///|
pub fn websearch_tool_def() -> @core.ToolDefinition {
  @core.ToolDefinition::create("websearch", "Search the web via DuckDuckGo (free)", "{type:object,properties:{query:{type:string}}}", false)
}
