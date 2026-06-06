///|
/// LTMA Desktop — REST API server.

///|
fn main {
  let host = setup_host()
  let html = load_html()
  println("LTMA Desktop — http://localhost:9090")
  @async.run_async_main(async fn() {
    let addr = @socket.Addr::parse("0.0.0.0:9090")
    let server = @async_http.Server::Server(addr)
    while true {
      let (conn, _) = server.accept()
      let req = conn.read_request()
      conn.send_response(200, "OK")
      if req.path == "/" || req.path == "/index.html" {
        conn.write_string(html)
      } else {
        conn.write_string("ok")
      }
      conn.end_response()
    }
  })
}

///|
fn load_html() -> String {
  try { @xfs.read_file_to_string("web/public/index.html") } catch { _ => "<h1>LTMA</h1>" }
}

///|
fn setup_host() -> @host.AgentHost {
  let host = @host.AgentHost::new()
  let reg = @tool.ToolRegistry::new()
  @builtin.register_builtins(reg)
  host.register(@agent.create_metadata("echo","Echo",["echo"]), fn() {
    let b = @agent.AgentBase::new(@agent.create_metadata("echo","Echo",["echo"]))
    @core.make_handle(b,fn(a){a.id()},fn(a){a.metadata()},fn(a,c){a.initialize(c)},
      fn(a,i){if i.is_text(){@core.Message::text("[Echo] "+i.get_text())}else{a.run(i)}},
      fn(a){a.shutdown()},fn(a){a.status()},fn(a,c){a.execute_tool(c)})
  })
  let p = @llm.create_mock_provider("Hello from LTMA Desktop!")
  host.register(@agent.create_metadata("chat","Chat",["chat"]), fn() { @agents.create_chat_agent_handle(p, reg) })
  host
}
