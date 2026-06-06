///|
/// HTTP server for the LTMA web API.
/// Targets JS backend using the Fetch API.

///|
extern "js" fn _js_fetch(url : String, options : String) -> String = "globalThis.fetch"

///|
pub struct WebServer {
  host : @host.AgentHost
  port : Int
}

///|
pub fn WebServer::new(host : @host.AgentHost, port : Int) -> WebServer {
  { host, port }
}

///|
pub fn WebServer::handle_request(
  self : WebServer,
  http_method : String,
  path : String,
  body : String,
) -> String {
  if http_method == "POST" && path == "/api/chat" {
    self.handle_chat(body)
  } else if http_method == "GET" && path == "/api/agents" {
    self.list_agents()
  } else if http_method == "POST" && path == "/api/a2a" {
    self.handle_a2a(body)
  } else if http_method == "GET" && path == "/api/health" {
    "{\"status\":\"ok\",\"version\":\"0.1.0\"}"
  } else {
    "{\"error\":\"not found\"}"
  }
}

///|
fn WebServer::handle_chat(self : WebServer, body : String) -> String {
  let agent_name = extract_json_str(body, "agent").unwrap_or("chat")
  let message = extract_json_str(body, "message").unwrap_or("")
  let id = @core.AgentId::create(agent_name, "0.1.0", "livingtree/ltma")
  match self.host.activate(id) {
    Some(adapter) => {
      let resp = adapter.call(@core.Message::text(message))
      adapter.shutdown()
      if resp.is_text() {
        "{\"response\":\"" + resp.get_text() + "\"}"
      } else {
        "{\"response\":\"<non-text>\"}"
      }
    }
    None => "{\"error\":\"agent not found: " + agent_name + "\"}"
  }
}

///|
fn WebServer::list_agents(self : WebServer) -> String {
  let agents = self.host.list_registered()
  let mut result = "{\"agents\":["
  let mut first = true
  for a in agents {
    if !first {
      result = result + ","
    }
    result = result +
      "{\"name\":\"" +
      a.id.name +
      "\",\"description\":\"" +
      a.description +
      "\"}"
    first = false
  }
  result + "]}"
}

///|
fn WebServer::handle_a2a(self : WebServer, body : String) -> String {
  let router = @protocol.A2ARouter::new()
  router.register("echo", @protocol.create_echo_handler())
  match @protocol.decode_message(body) {
    Some(msg) =>
      match router.send(msg) {
        Some(resp) => @protocol.encode_message(resp)
        None => "{\"error\":\"no handler\"}"
      }
    None => "{\"error\":\"invalid A2A message\"}"
  }
}

///|
fn extract_json_str(json : String, field : String) -> String? {
  let search = "\"" + field + "\":\""
  match json.find(search) {
    Some(start) => {
      let view = json.sub(start=start + search.length())
      match view.find("\"") {
        Some(end) => Some(view.sub(start=0, end~).to_owned())
        None => None
      }
    }
    None => None
  }
}
