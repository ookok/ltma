///|
/// HTTP REST API server for LTMA — serves agent chat endpoints.

///|
pub struct App {
  host : @host.AgentHost
  port : Int
}

///|
pub fn App::new(host : @host.AgentHost, port : Int) -> App {
  { host, port }
}

///|
pub async fn App::start(self : App) -> Unit {
  let addr = "0.0.0.0:" + self.port.to_string()
  let server = @async_http.Server::Server(addr)
  println("REST API listening on http://\{addr}")
  loop {
    let (conn, _addr) = server.accept()
    let req = conn.read_request()
    let body = read_body(conn)
    let resp_body = self.handle(req.method, req.path, body)
    conn.send_response(body=@io.Data::from_bytes(@encoding/utf8.encode(resp_body)))
    conn.end_response()
  }
}

///|
fn read_body(conn : @async_http.ServerConnection) -> String {
  let mut buf = FixedArray::make(4096, b'\x00')
  let n = conn.read(buf)
  if n > 0 {
    @encoding/utf8.decode_lossy(buf.view(0, n))
  } else {
    ""
  }
}

///|
fn App::handle(
  self : App,
  method : String,
  path : String,
  body : String,
) -> String {
  if method == "GET" && path == "/health" {
    "{\"status\":\"ok\",\"version\":\"0.1.0\"}"
  } else if method == "GET" && path == "/agents" {
    list_agents_json(self.host)
  } else if method == "POST" && path == "/chat" {
    handle_chat(self.host, body)
  } else {
    json_error("not found", 404)
  }
}

///|
fn list_agents_json(host : @host.AgentHost) -> String {
  let agents = host.list_registered()
  let mut result = "{\"agents\":["
  let mut first = true
  for a in agents {
    if !first {
      result = result + ","
    }
    result = result +
      "{\"id\":\"" +
      a.id.name +
      "\",\"desc\":\"" +
      a.description +
      "\"}"
    first = false
  }
  result + "]}"
}

///|
fn handle_chat(host : @host.AgentHost, body : String) -> String {
  let agent = extract_json_field(body, "agent").unwrap_or("echo")
  let msg = extract_json_field(body, "message").unwrap_or("hello")
  let id = @core.AgentId::create(agent, "0.1.0", "livingtree/ltma")
  match host.activate(id) {
    Some(adapter) => {
      let resp = adapter.call(@core.Message::text(msg))
      adapter.shutdown()
      if resp.is_text() {
        "{\"response\":\"" + resp.get_text() + "\"}"
      } else {
        json_error("non-text response", 500)
      }
    }
    None => json_error("agent not found: " + agent, 404)
  }
}

///|
fn extract_json_field(json : String, field : String) -> String? {
  let search = "\"" + field + "\":\""
  match json.find(search) {
    Some(start) => {
      let after = json.sub(start=start + search.length())
      match after.find("\"") {
        Some(end) => Some(after.sub(start=0, end~).to_owned())
        None => None
      }
    }
    None => None
  }
}

///|
fn json_error(msg : String, code : Int) -> String {
  "{\"error\":\"" + msg + "\",\"code\":" + code.to_string() + "}"
}
