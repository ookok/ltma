///|
/// TUI Interactive Chat — direct VNodeApp with manual re-render.

///|
pub fn start_chat_tui(host : @host.AgentHost) -> Unit {
  let (w, h) = @miztui.get_terminal_size()
  let (app, stop_app) = @vnode.init_vnode_terminal(
    w,
    h,
    fn(s) { @tui_io.print_raw(s) },
    mouse=false,
    raw_mode=true,
  )

  let messages : Array[String] = []
  let mut input_buf = ""

  // Initial render
  let _ = app.render(render_chat(messages, input_buf))

  // Keypress listener
  @tui_io.start_keypress_listener(fn(key) {
    if key == "\r" || key == "\n" {
      if input_buf != "" {
        let msg = input_buf
        input_buf = ""
        messages.push(msg)
        let id = @core.AgentId::create("echo", "0.1.0", "livingtree/ltma")
        match host.activate(id) {
          Some(a) => {
            let resp = a.call(@core.Message::text(msg))
            if resp.is_text() {
              messages.push(resp.get_text())
            }
            a.shutdown()
          }
          None => messages.push("[agent unavailable]")
        }
        let _ = app.render(render_chat(messages, input_buf))
      }
    } else if key == "\u001b" {
      @tui_io.stop_keypress_listener()
      stop_app()
    } else if key.length() == 1 {
      input_buf = input_buf + key
      let _ = app.render(render_chat(messages, input_buf))
    }
  })
}

///|
fn render_chat(messages : Array[String], input_text : String) -> @vnode.TuiNode {
  let children : Array[@vnode.TuiNode] = []
  children.push(@miztui.text("LTMA Chat (ESC to quit)", bold=true, fg="cyan"))
  children.push(@miztui.text(""))

  for i = 0; i < messages.length(); i = i + 1 {
    let prefix = if i % 2 == 0 { "You: " } else { "AI: " }
    let color = if i % 2 == 0 { "green" } else { "white" }
    children.push(@miztui.text("\{prefix}\{messages[i]}", fg=color))
  }

  children.push(@miztui.text(""))
  children.push(@miztui.input(input_text, placeholder="Type here..."))

  @miztui.column(gap=1.0, padding=1.0, children)
}
