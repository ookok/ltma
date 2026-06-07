///|
/// Basic markdown → TuiNode renderer.
/// Supports **bold**, *italic*, `code`, code blocks, links.
pub enum MdNode {
  Text(String)
  Bold(Array[MdNode])
  Italic(Array[MdNode])
  Code(String)
  CodeBlock(String, String)
  Link(String, String)
}

///|
fn find_sub(haystack : StringView, start : Int, needle : StringView) -> Int {
  match haystack[start:].find(needle) {
    Some(rel) => start + rel
    None => -1
  }
}

///|
fn parse_inline_impl(s : StringView) -> (Array[MdNode], Int) {
  let nodes : Array[MdNode] = []
  let mut i = 0
  let len = s.length()
  let mut buf = StringBuilder()
  while i < len {
    let ch = s[i]
    if ch == 0x5C && i + 1 < len {
      buf.write_char(Int::unsafe_to_char(s[i + 1].to_int()))
      i = i + 2
    } else if ch == 0x2A {
      let text = buf.to_string()
      if text.length() > 0 {
        nodes.push(Text(text))
        buf = StringBuilder()
      }
      if i + 1 < len && s[i + 1] == 0x2A {
        let end = find_sub(s, i + 2, "**"[:])
        if end >= 0 {
          let (inner, _) = parse_inline_impl(s[i + 2:end])
          nodes.push(Bold(inner))
          i = end + 2
        } else {
          buf.write_string("**")
          i = i + 2
        }
      } else {
        let end = find_sub(s, i + 1, "*"[:])
        if end >= 0 && !(end + 1 < len && s[end + 1] == 0x2A) {
          let (inner, _) = parse_inline_impl(s[i + 1:end])
          nodes.push(Italic(inner))
          i = end + 1
        } else {
          buf.write_string("*")
          i = i + 1
        }
      }
    } else if ch == 0x60 {
      let text = buf.to_string()
      if text.length() > 0 {
        nodes.push(Text(text))
        buf = StringBuilder()
      }
      if i + 2 < len && s[i + 1] == 0x60 && s[i + 2] == 0x60 {
        let end = find_sub(s, i + 3, "```"[:])
        if end >= 0 {
          let code_s = s[i + 3:end].to_owned()
          let nl = find_sub(code_s[:], 0, "\n"[:])
          if nl >= 0 {
            nodes.push(
              CodeBlock(code_s[:nl].to_owned(), code_s[nl + 1:].to_owned()),
            )
          } else {
            nodes.push(CodeBlock("", code_s))
          }
          i = end + 3
        } else {
          buf.write_string("```")
          i = i + 3
        }
      } else {
        let end = find_sub(s, i + 1, "`"[:])
        if end >= 0 {
          nodes.push(Code(s[i + 1:end].to_owned()))
          i = end + 1
        } else {
          buf.write_string("`")
          i = i + 1
        }
      }
    } else if ch == 0x5B {
      let text = buf.to_string()
      if text.length() > 0 {
        nodes.push(Text(text))
        buf = StringBuilder()
      }
      let cb = find_sub(s, i + 1, "]"[:])
      if cb >= 0 && cb + 1 < len && s[cb + 1] == 0x28 {
        let cp = find_sub(s, cb + 2, ")"[:])
        if cp >= 0 {
          nodes.push(Link(s[i + 1:cb].to_owned(), s[cb + 2:cp].to_owned()))
          i = cp + 1
        } else {
          buf.write_string("[")
          i = i + 1
        }
      } else {
        buf.write_string("[")
        i = i + 1
      }
    } else {
      buf.write_char(Int::unsafe_to_char(ch.to_int()))
      i = i + 1
    }
  }
  let remaining = buf.to_string()
  if remaining.length() > 0 {
    nodes.push(Text(remaining))
  }
  (nodes, i)
}

///|
pub fn parse_markdown(text : String) -> Array[MdNode] {
  let lines = text.split("\n").to_array()
  let nodes : Array[MdNode] = []
  let mut i = 0
  while i < lines.length() {
    let line = lines[i]
    if line.has_prefix("```") {
      let lang = if line.length() > 3 { line[3:].to_owned() } else { "" }
      let code_parts : Array[String] = []
      let mut j = i + 1
      while j < lines.length() {
        if lines[j] == "```" {
          nodes.push(CodeBlock(lang, code_parts.join("\n")))
          i = j + 1
          break
        }
        code_parts.push(lines[j].to_owned())
        j = j + 1
      }
      if j >= lines.length() {
        nodes.push(CodeBlock(lang, code_parts.join("\n")))
        i = j
      }
    } else if line.has_prefix("### ") {
      let (inline_nodes, _) = parse_inline_impl(line[4:][:])
      nodes.push(Bold(inline_nodes))
      nodes.push(Text("\n"))
      i = i + 1
    } else if line.has_prefix("## ") {
      let (inline_nodes, _) = parse_inline_impl(line[3:][:])
      nodes.push(Bold(inline_nodes))
      nodes.push(Text("\n"))
      i = i + 1
    } else if line.has_prefix("# ") {
      let (inline_nodes, _) = parse_inline_impl(line[2:][:])
      nodes.push(Bold(inline_nodes))
      nodes.push(Text("\n"))
      i = i + 1
    } else if line.has_prefix("- ") {
      nodes.push(Text("  • "))
      let (inline_nodes, _) = parse_inline_impl(line[2:][:])
      nodes.append(inline_nodes)
      nodes.push(Text("\n"))
      i = i + 1
    } else {
      if line.length() > 0 {
        let (inline_nodes, _) = parse_inline_impl(line[:])
        nodes.append(inline_nodes)
      }
      nodes.push(Text("\n"))
      i = i + 1
    }
  }
  nodes
}

///|
pub fn md_to_vnode(nodes : Array[MdNode], theme : Theme) -> @vnode.TuiNode {
  let children = []
  for node in nodes {
    match node {
      Text(s) => children.push(@vnode.text(s, fg=theme.text))
      Bold(inner) =>
        for child in inner {
          match child {
            Text(s) =>
              children.push(@vnode.text(s, fg=theme.text_bright, bold=true))
            Code(s) =>
              children.push(@vnode.text(s, fg=theme.primary, bold=true))
            _ => children.push(md_to_vnode([child], theme))
          }
        }
      Italic(inner) =>
        for child in inner {
          match child {
            Text(s) => children.push(@vnode.text(s, fg=theme.secondary))
            Code(s) => children.push(@vnode.text(s, fg=theme.secondary))
            _ => children.push(md_to_vnode([child], theme))
          }
        }
      Code(s) => children.push(@vnode.text(s, fg=theme.primary))
      CodeBlock(lang, code) => {
        let line_nodes = []
        if lang.length() > 0 {
          line_nodes.push(@vnode.text(lang, fg=theme.text_dim))
        }
        let parts = code.split("\n")
        for cl in parts {
          line_nodes.push(@vnode.text(cl.to_owned(), fg=theme.primary))
        }
        children.push(
          @vnode.column(
            bg=theme.code_bg,
            border="single",
            padding=1.0,
            margin_y=1.0,
            line_nodes,
          ),
        )
      }
      Link(text, url) =>
        children.push(
          @vnode.text("\{text}(\{url})", fg=theme.primary, underline=true),
        )
    }
  }
  @vnode.fragment(children)
}
