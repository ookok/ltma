///|
/// TUI Interactive Chat — signal-reactive with streaming, scrolling, mouse, history.
pub fn start_chat_tui(host : @host.AgentHost) -> Unit {
  let renderer = @engine.EngineRenderer::from_terminal(fn(s) {
    @tui_io.print_raw(s)
  })

  let messages = @signals.Signal::new([])
  let input_buf = @signals.Signal::new("")
  let cur_theme = @signals.Signal::new(@engine.Theme::dark())
  let streaming_idx = @signals.Signal::new(Option::None)
  let spinner_frame = @signals.Signal::new(0)
  let stream_buf = @engine.StreamingBuffer::new()
  let spinner = @engine.default_spinner()
  let input_history = @signals.Signal::new([])
  let history_pos = @signals.Signal::new(0)
  let scroll_top = @signals.Signal::new(0)

  fn trim_messages(ms : Array[@engine.ChatMessage]) -> Array[@engine.ChatMessage] {
    if ms.length() > 200 {
      let start = ms.length() - 200
      let result : Array[@engine.ChatMessage] = []
      for i = start; i < ms.length(); i = i + 1 {
        result.push(ms[i])
      }
      result
    } else {
      ms
    }
  }

  let stop_render = renderer.render(fn() {
    @engine.chat_ui(
      messages.get(),
      input_buf.get(),
      theme=cur_theme.get(),
      streaming_id=streaming_idx.get(),
      scroll_top=scroll_top.get(),
      spinner_frame=spinner_frame.get(),
      spinner~,
    )
  })

  @tui_io.start_resize_listener(fn(_w, _h) { renderer.resize() })

  @tui_io.set_idle_handler(fn() {
    spinner_frame.set((spinner_frame.get() + 1) % spinner.length())
    if !stream_buf.is_complete() {
      stream_buf.reveal_n(3)
      let display = stream_buf.display()
      messages.update(fn(ms) {
        match streaming_idx.get() {
          Some(idx) if idx < ms.length() => {
            ms[idx] = @engine.ChatMessage::new("assistant", display)
            ms
          }
          _ => ms
        }
      })
      if stream_buf.is_complete() {
        streaming_idx.set(Option::None)
      }
    }
  })

  @tui_io.start_keypress_listener(fn(key) {
    let ev = @mtui.parse_input(key)
    match ev {
      @mtui.InputEvent::Key(@mtui.KeyEvent::Special(@mtui.SpecialKey::Enter, _)) => {
        let msg = input_buf.get()
        if msg != "" {
          input_buf.set("")
          messages.update(fn(ms) {
            trim_messages(ms + [@engine.ChatMessage::new("user", msg)])
          })
          input_history.update(fn(h) { h + [msg] })
          history_pos.set(input_history.get().length())
          scroll_top.set(0)
          let idx = messages.get().length()
          messages.update(fn(ms) {
            trim_messages(ms + [@engine.ChatMessage::new("assistant", "Thinking...")])
          })
          streaming_idx.set(Some(idx))
          let id = @core.AgentId::create("echo", "0.1.0", "livingtree/ltma")
          match host.activate(id) {
            Some(a) => {
              let resp = a.call(@core.Message::text(msg))
              let text = if resp.is_text() { resp.get_text() } else { "" }
              stream_buf.set_text(text)
              stream_buf.reveal_all()
              messages.update(fn(ms) {
                match streaming_idx.get() {
                  Some(idx) if idx < ms.length() => {
                    ms[idx] = @engine.ChatMessage::new("assistant", text)
                    ms
                  }
                  _ => ms
                }
              })
              streaming_idx.set(Option::None)
              stream_buf.clear()
              a.shutdown()
            }
            None => {
              messages.update(fn(ms) {
                match streaming_idx.get() {
                  Some(idx) if idx < ms.length() => {
                    ms[idx] = @engine.ChatMessage::new("assistant", "[agent unavailable]")
                    ms
                  }
                  _ => ms
                }
              })
              streaming_idx.set(Option::None)
            }
          }
        }
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Special(@mtui.SpecialKey::Escape, _)) => {
        @tui_io.stop_keypress_listener()
        renderer.shutdown(stop_render)
        @tui_io.cleanup_stdin()
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Char('c', @mtui.KeyModifier::Ctrl)) => {
        @tui_io.stop_keypress_listener()
        renderer.shutdown(stop_render)
        @tui_io.cleanup_stdin()
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Char('t', @mtui.KeyModifier::Ctrl)) => {
        let cur = cur_theme.get()
        cur_theme.set(if cur.name == "dark" { @engine.Theme::light() } else { @engine.Theme::dark() })
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Special(@mtui.SpecialKey::Backspace, _)) => {
        let b = input_buf.get()
        if b.length() > 0 {
          input_buf.set(b[:b.length() - 1].to_owned())
        }
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Special(@mtui.SpecialKey::Tab, _)) =>
        input_buf.update(fn(b) { b + "  " })
      @mtui.InputEvent::Key(@mtui.KeyEvent::Special(@mtui.SpecialKey::Up, _)) => {
        let pos = history_pos.get()
        let history = input_history.get()
        if pos > 0 {
          history_pos.set(pos - 1)
          input_buf.set(history[pos - 1])
        }
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Special(@mtui.SpecialKey::Down, _)) => {
        let pos = history_pos.get()
        let history = input_history.get()
        if pos < history.length() - 1 {
          history_pos.set(pos + 1)
          input_buf.set(history[pos + 1])
        } else {
          history_pos.set(history.length())
          input_buf.set("")
        }
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Special(@mtui.SpecialKey::PageUp, _)) => {
        let cur = scroll_top.get()
        let max = if messages.get().length() > 10 { messages.get().length() - 10 } else { 0 }
        scroll_top.set(if cur + 5 > max { max } else { cur + 5 })
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Special(@mtui.SpecialKey::PageDown, _)) => {
        let cur = scroll_top.get()
        scroll_top.set(if cur < 5 { 0 } else { cur - 5 })
      }
      @mtui.InputEvent::Key(@mtui.KeyEvent::Char(c, _)) => {
        let code = c.to_int()
        if code == 8 {
          let b = input_buf.get()
          if b.length() > 0 {
            input_buf.set(b[:b.length() - 1].to_owned())
          }
        } else {
          input_buf.update(fn(b) { b + Char::to_string(c) })
        }
      }
      @mtui.InputEvent::Mouse(m) => {
        match m.button {
          @mtui.MouseButton::ScrollUp => {
            let cur = scroll_top.get()
            let max = if messages.get().length() > 10 { messages.get().length() - 10 } else { 0 }
            scroll_top.set(if cur + 3 > max { max } else { cur + 3 })
          }
          @mtui.MouseButton::ScrollDown => {
            let cur = scroll_top.get()
            scroll_top.set(if cur < 3 { 0 } else { cur - 3 })
          }
          _ => ()
        }
      }
      _ => ()
    }
  })
}
