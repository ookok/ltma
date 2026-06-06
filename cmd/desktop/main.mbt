///|
/// LTMA Desktop — native webview client.

///|
fn main {
  let host = setup_host()

  println("LTMA Desktop starting...")
  println("Embedded chat UI loaded in native window.")

  let wv = @webview.Webview::new()
  wv.set_debug(1)
  wv.set_title("LTMA Chat")
  wv.set_size(900, 680, 0)
  wv.set_html(chat_html())
  wv.run()
}

///|
fn chat_html() -> String {
  try { @xfs.read_file_to_string("web/public/index.html") } catch { _ => "<html><body><h1>Loading...</h1></body></html>" }
}

///|
fn setup_host() -> @host.AgentHost {
  let host = @host.AgentHost::new()
  let registry = @tool.ToolRegistry::new()
  @builtin.register_builtins(registry)

  let echo_meta = @agent.create_metadata("echo", "Echo", ["echo"])
  host.register(echo_meta, fn() { echo_handle() })

  let provider = @llm.create_mock_provider("Hello from LTMA Desktop!")
  let chat_handle = @agents.create_chat_agent_handle(provider, registry)
  let chat_meta = @agent.create_metadata("chat", "Chat", ["chat"])
  host.register(chat_meta, fn() { chat_handle })

  host
}

///|
fn echo_handle() -> @core.AgentHandle {
  let meta = @agent.create_metadata("echo", "Echo", ["echo"])
  let base = @agent.AgentBase::new(meta)
  @core.make_handle(
    base,
    fn(a) { a.id() },
    fn(a) { a.metadata() },
    fn(a, ctx) { a.initialize(ctx) },
    fn(a, input) {
      if input.is_text() {
        @core.Message::text("[Echo] " + input.get_text())
      } else {
        a.run(input)
      }
    },
    fn(a) { a.shutdown() },
    fn(a) { a.status() },
    fn(a, call) { a.execute_tool(call) },
  )
}
