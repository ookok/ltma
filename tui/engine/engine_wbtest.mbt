///|
/// Whitebox tests for markdown parser internals.
test "find_sub finds substring in StringView" {
  let s = "hello world"[:]
  let pos = find_sub(s, 0, "world"[:])
  inspect(pos, content="6")
}

///|
test "find_sub returns -1 for missing substring" {
  let s = "hello"[:]
  let pos = find_sub(s, 0, "xyz"[:])
  inspect(pos, content="-1")
}

///|
test "find_sub respects start offset" {
  let s = "aaa"[:]
  let pos = find_sub(s, 1, "a"[:])
  inspect(pos, content="1")
}

///|
test "parse_inline_impl plain text" {
  let s = "hello"[:]
  let (nodes, _) = parse_inline_impl(s)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    Text(t) => inspect(t, content="hello")
    _ => fail("expected Text")
  }
}

///|
test "parse_inline_impl bold text" {
  let s = "**bold**"[:]
  let (nodes, _) = parse_inline_impl(s)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    Bold(inner) => {
      inspect(inner.length(), content="1")
      match inner[0] {
        Text(t) => inspect(t, content="bold")
        _ => fail("expected Text inside Bold")
      }
    }
    _ => fail("expected Bold")
  }
}

///|
test "parse_inline_impl italic text" {
  let s = "*italic*"[:]
  let (nodes, _) = parse_inline_impl(s)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    Italic(inner) => {
      inspect(inner.length(), content="1")
      match inner[0] {
        Text(t) => inspect(t, content="italic")
        _ => fail("expected Text inside Italic")
      }
    }
    _ => fail("expected Italic")
  }
}

///|
test "parse_inline_impl inline code" {
  let s = "`code`"[:]
  let (nodes, _) = parse_inline_impl(s)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    Code(c) => inspect(c, content="code")
    _ => fail("expected Code")
  }
}

///|
test "parse_markdown plain text" {
  let nodes = parse_markdown("hello")
  inspect(nodes.length() > 0, content="true")
  match nodes[0] {
    Text(t) => inspect(t, content="hello")
    _ => fail("expected Text")
  }
}

///|
test "parse_markdown code block" {
  let nodes = parse_markdown("```\nlet x = 1\n```")
  let mut found : String? = None
  for n in nodes {
    match n {
      CodeBlock(lang, code) => {
        found = Some(lang + ":" + code)
        break
      }
      _ => ()
    }
  }
  match found {
    Some(val) => inspect(val, content=":let x = 1")
    None => fail("expected CodeBlock")
  }
}

///|
test "parse_markdown code block with lang" {
  let nodes = parse_markdown("```python\nprint(1)\n```")
  let mut found : String? = None
  for n in nodes {
    match n {
      CodeBlock(lang, code) => {
        found = Some(lang + ":" + code)
        break
      }
      _ => ()
    }
  }
  match found {
    Some(val) => inspect(val, content="python:print(1)")
    None => fail("expected CodeBlock with lang")
  }
}

///|
test "parse_markdown mixed formatting" {
  let nodes = parse_markdown("hello **world**")
  inspect(nodes.length() >= 2, content="true")
  match nodes[0] {
    Text(t) => inspect(t, content="hello ")
    _ => fail("expected Text")
  }
  match nodes[1] {
    Bold(_) => ()
    _ => fail("expected Bold")
  }
}

///|
test "StreamingBuffer append and display" {
  let buf = StreamingBuffer::new()
  buf.append("hel")
  buf.append("lo")
  buf.reveal_all()
  inspect(buf.display(), content="hello")
}

///|
test "StreamingBuffer partial reveal" {
  let buf = StreamingBuffer::new()
  buf.append("hello")
  buf.reveal_one_more()
  buf.reveal_one_more()
  buf.reveal_one_more()
  inspect(buf.display(), content="hel")
  inspect(buf.is_complete(), content="false")
}

///|
test "StreamingBuffer clear" {
  let buf = StreamingBuffer::new()
  buf.set_text("hello")
  buf.clear()
  inspect(buf.display(), content="")
}

///|
test "StreamingBuffer reveal_n reveals multiple chars" {
  let buf = StreamingBuffer::new()
  buf.set_text("hello world")
  buf.reveal_n(5)
  inspect(buf.display(), content="hello")
  inspect(buf.is_complete(), content="false")
  buf.reveal_n(20)
  inspect(buf.is_complete(), content="true")
  inspect(buf.display(), content="hello world")
}

///|
test "Theme dark preset" {
  let t = Theme::dark()
  inspect(t.primary == "cyan", content="true")
  inspect(t.text == "rgb(220,220,230)", content="true")
}

///|
test "Theme light preset" {
  let t = Theme::light()
  inspect(t.primary == "blue", content="true")
  inspect(t.text == "rgb(40,40,50)", content="true")
}

///|
test "md_to_vnode renders plain text" {
  let theme = Theme::dark()
  let md_nodes = parse_markdown("hello")
  let result = md_to_vnode(md_nodes, theme)
  let rendered = @vnode.render_vnode_once(80, 24, result)
  inspect(rendered.length() > 0, content="true")
}

///|
test "md_to_vnode renders bold with code" {
  let theme = Theme::dark()
  let md_nodes = parse_markdown("**hello `code` world**")
  let result = md_to_vnode(md_nodes, theme)
  let rendered = @vnode.render_vnode_once(80, 24, result)
  inspect(rendered.length() > 0, content="true")
}

///|
test "md_to_vnode renders code block" {
  let theme = Theme::dark()
  let md_nodes = parse_markdown("```\nlet x = 1\n```")
  let result = md_to_vnode(md_nodes, theme)
  let rendered = @vnode.render_vnode_once(80, 24, result)
  inspect(rendered.length() > 0, content="true")
}

///|
test "md_to_vnode renders link" {
  let theme = Theme::dark()
  let md_nodes = parse_markdown("[text](url)")
  let result = md_to_vnode(md_nodes, theme)
  let rendered = @vnode.render_vnode_once(80, 24, result)
  inspect(rendered.length() > 0, content="true")
}

///|
test "parse_markdown heading produces Bold" {
  let nodes = parse_markdown("# Hello")
  let mut found_bold = false
  for n in nodes {
    match n {
      Bold(_) => found_bold = true
      _ => ()
    }
  }
  inspect(found_bold, content="true")
}

///|
test "parse_markdown bullet produces bullet prefix" {
  let nodes = parse_markdown("- item")
  let mut found_bullet = false
  for n in nodes {
    match n {
      Text(t) => if t.has_prefix("  • ") { found_bullet = true }
      _ => ()
    }
  }
  inspect(found_bullet, content="true")
}

///|
test "parse_markdown heading level 2" {
  let nodes = parse_markdown("## Subheading")
  let mut found_bold = false
  for n in nodes {
    match n {
      Bold(inner) => {
        found_bold = true
        match inner[0] {
          Text(t) => inspect(t, content="Subheading")
          _ => fail("expected Text inside Bold")
        }
      }
      _ => ()
    }
  }
  inspect(found_bold, content="true")
}

///|
test "parse_markdown heading level 3" {
  let nodes = parse_markdown("### Deep")
  let mut found = false
  for n in nodes {
    match n {
      Bold(_) => found = true
      _ => ()
    }
  }
  inspect(found, content="true")
}

///|
test "parse_markdown mixed headings and text" {
  let nodes = parse_markdown("# Title\n\nSome text")
  let mut bold_count = 0
  let mut text_count = 0
  for n in nodes {
    match n {
      Bold(_) => bold_count = bold_count + 1
      Text(t) => if t.length() > 1 { text_count = text_count + 1 }
      _ => ()
    }
  }
  inspect(bold_count, content="1")
  inspect(text_count > 0, content="true")
}

///|
test "ChatMessage new creates message struct" {
  let m = ChatMessage::new("user", "hello")
  inspect(m.role, content="user")
  inspect(m.content, content="hello")
}

///|
test "chat_bubble renders user message" {
  let theme = Theme::dark()
  let msg = ChatMessage::new("user", "hello")
  let result = chat_bubble(
    msg,
    theme~,
    is_streaming=false,
    spinner_frame=None,
    spinner=default_spinner(),
  )
  let rendered = @vnode.render_vnode_once(80, 24, result)
  inspect(rendered.length() > 0, content="true")
}

///|
test "chat_bubble renders ai message" {
  let theme = Theme::dark()
  let msg = ChatMessage::new("assistant", "hi there")
  let result = chat_bubble(
    msg,
    theme~,
    is_streaming=false,
    spinner_frame=None,
    spinner=default_spinner(),
  )
  let rendered = @vnode.render_vnode_once(80, 24, result)
  inspect(rendered.length() > 0, content="true")
}

///|
test "chat_bubble renders streaming message" {
  let theme = Theme::dark()
  let msg = ChatMessage::new("assistant", "typing...")
  let result = chat_bubble(
    msg,
    theme~,
    is_streaming=true,
    spinner_frame=Some(0),
    spinner=default_spinner(),
  )
  let rendered = @vnode.render_vnode_once(80, 24, result)
  inspect(rendered.length() > 0, content="true")
}

///|
test "chat_ui renders with messages" {
  let theme = Theme::dark()
  let msgs = [
    ChatMessage::new("user", "hello"),
    ChatMessage::new("assistant", "world"),
  ]
  let result = chat_ui(
    msgs,
    "",
    theme~,
    streaming_id=None,
    scroll_top=0,
    spinner=default_spinner(),
  )
  let rendered = @vnode.render_vnode_once(80, 24, result)
  inspect(rendered.length() > 0, content="true")
}
