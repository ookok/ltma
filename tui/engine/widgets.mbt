///|
/// High-level widgets for LLM chat UI.
pub struct ChatMessage {
  role : String
  content : String
}

///|
pub fn ChatMessage::new(role : String, content : String) -> ChatMessage {
  { role, content }
}

///|
pub fn chat_ui(
  messages : Array[ChatMessage],
  input_buf : String,
  theme~ : Theme,
  streaming_id~ : Int?,
  scroll_top~ : Int,
  spinner_frame? : Int,
  spinner? : Array[String],
) -> @vnode.TuiNode {
  let sp_arr = match spinner {
    Some(s) => s
    None => default_spinner()
  }
  let header = @vnode.row([
    @vnode.text(" LTMA Chat ", fg=theme.primary, bold=true),
    @vnode.text("  (ESC quit, Ctrl+T theme)", fg=theme.text_dim),
  ])
  let msg_nodes = []
  for i = scroll_top; i < messages.length(); i = i + 1 {
    let msg = messages[i]
    let is_streaming = match streaming_id {
      Some(idx) => idx == i
      None => false
    }
    if i > scroll_top {
      msg_nodes.push(
        @vnode.text("  " + "─".repeat(38) + "  ", fg=theme.border),
      )
    }
    msg_nodes.push(
      chat_bubble(msg, theme~, is_streaming~, spinner_frame~, spinner=sp_arr),
    )
  }
  let msg_view = @vnode.view(
    direction="column",
    flex_grow=1.0,
    padding_x=1.0,
    msg_nodes,
  )
  let input_row = @vnode.row([
    @vnode.text("> ", fg=theme.text_dim),
    @vnode.textarea(
      input_buf,
      placeholder="Type a message... (Shift+Enter to send)",
      rows=3,
      fg=theme.text,
      placeholder_fg=theme.text_dim,
      focus_border_color=theme.accent,
      padding_x=1.0,
    ),
  ])
  @vnode.column(gap=1.0, padding=1.0, [header, msg_view, input_row])
}

///|
pub fn chat_bubble(
  msg : ChatMessage,
  theme~ : Theme,
  is_streaming~ : Bool,
  spinner_frame~ : Int?,
  spinner~ : Array[String],
) -> @vnode.TuiNode {
  let is_user = msg.role == "user"
  let role_color = if is_user { theme.success } else { theme.primary }
  let role_label = if is_user { "You" } else { "AI" }
  let role_tag = if is_streaming {
    match spinner_frame {
      Some(f) => {
        let sp = spinner_char(spinner, f)
        "\{sp} \{role_label}..."
      }
      None => "\{role_label} (typing...)"
    }
  } else {
    role_label
  }
  let bg = if is_user { theme.surface_alt } else { "" }
  let md_nodes = parse_markdown(msg.content)
  let content_node = md_to_vnode(md_nodes, theme)
  @vnode.column(bg~, padding_x=1.0, [
    @vnode.text(role_tag, fg=role_color, bold=true),
    content_node,
  ])
}
