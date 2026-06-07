///|
/// QueryHandle — wraps tree-sitter query compilation and execution.

///|
/// QueryHandle — compiled tree-sitter query.
pub struct QueryHandle {
  mut ptr : Int64
  lang_ptr : Int64
}

///|
pub fn QueryHandle::new(lang_ptr : Int64) -> QueryHandle {
  { ptr: 0L, lang_ptr }
}

///|
/// Compile a query pattern. Returns false if pattern has syntax errors.
pub fn QueryHandle::compile(self : QueryHandle, pattern : String) -> Bool {
  let bytes = @utf8.encode(pattern)
  let q = _ts_query_new(self.lang_ptr, bytes, bytes.length())
  if q == 0L {
    false
  } else {
    self.ptr = q
    true
  }
}

///|
pub fn QueryHandle::free(self : QueryHandle) -> Unit {
  if self.ptr != 0L {
    _ts_query_free(self.ptr)
  }
}

///|
/// Result of a query execution: array of matches, each with captures.
pub fn query_matches(
  query : QueryHandle,
  node : SyntaxNode,
) -> Array[QueryMatch] {
  let cursor = _ts_query_cursor_new()
  let _ = _ts_query_cursor_exec(cursor, query.ptr, node.data)
  let results : Array[QueryMatch] = []
  while true {
    let raw = _ts_query_cursor_next_match(cursor, query.ptr)
    if raw.length() == 0 {
      break
    } else {
      match parse_match_json(raw) {
        Some(m) => results.push(m)
        None => ()
      }
    }
  }
  _ts_query_cursor_free(cursor)
  results
}

///|
/// Parse a JSON match result from the C stub.
fn parse_match_json(raw : Bytes) -> QueryMatch? {
  let text = @utf8.decode_lossy(raw)
  let pat_marker = "\"pattern\":"
  let pat_start = text.find(pat_marker)
  let pat_start_val = match pat_start {
    Some(v) => v
    None => return None
  }
  let pat_idx_str = text[pat_start_val + pat_marker.length():].to_owned()
  let pat_val_end = pat_idx_str.find(",")
  let pat_num_str = match pat_val_end {
    Some(e) => pat_idx_str[:e].to_owned()
    None => return None
  }
  let pattern_index = @string.parse_int(pat_num_str) catch { _ => return None }

  let cap_marker = "\"captures\":["
  let cap_start = text.find(cap_marker)
  let cap_start_val = match cap_start {
    Some(v) => v
    None => return Some(QueryMatch::new(pattern_index, []))
  }
  let cap_body = text[cap_start_val + cap_marker.length():].to_owned()
  let mut depth = 1
  let mut cap_end = -1
  for i = 0; i < cap_body.length(); i = i + 1 {
    if cap_body[i] == 0x5B {
      depth = depth + 1
    } else if cap_body[i] == 0x5D {
      depth = depth - 1
      if depth == 0 {
        cap_end = i
        break
      }
    }
  }
  if cap_end < 0 {
    return Some(QueryMatch::new(pattern_index, []))
  }
  let cap_content = cap_body[:cap_end].to_owned()
  let captures : Array[Capture] = []
  let mut i = 0
  while i < cap_content.length() {
    while i < cap_content.length() && cap_content[i] != 0x7B {
      i = i + 1
    }
    if i >= cap_content.length() {
      break
    }
    let obj_start = i
    depth = 1
    let mut obj_end = -1
    let mut j = i + 1
    while j < cap_content.length() {
      if cap_content[j] == 0x7B {
        depth = depth + 1
      } else if cap_content[j] == 0x7D {
        depth = depth - 1
        if depth == 0 {
          obj_end = j
          break
        }
      }
      j = j + 1
    }
    if obj_end < 0 {
      break
    }
    let obj_text = cap_content[obj_start:obj_end + 1].to_owned()
    let name = extract_json_string(obj_text, "\"name\":\"")
    let kind = extract_json_string(obj_text, "\"type\":\"")
    let start_row = extract_json_int(obj_text, "\"start_row\":")
    let start_col = extract_json_int(obj_text, "\"start_col\":")
    let end_row = extract_json_int(obj_text, "\"end_row\":")
    let end_col = extract_json_int(obj_text, "\"end_col\":")
    match (name, kind, start_row, start_col, end_row, end_col) {
      (Some(n), Some(k), Some(sr), Some(sc), Some(er), Some(ec)) =>
        captures.push(
          Capture::new(n, k, Range::new(Point::new(sr, sc), Point::new(er, ec))),
        )
      _ => ()
    }
    i = obj_end + 1
  }
  Some(QueryMatch::new(pattern_index, captures))
}

///|
fn extract_json_string(text : String, key : String) -> String? {
  let start = text.find(key)
  match start {
    None => None
    Some(s) => {
      let after = s + key.length()
      let mut val = ""
      let mut i = after
      while i < text.length() && text[i] != 0x22 {
        val = val + text[i].to_string()
        i = i + 1
      }
      Some(val)
    }
  }
}

///|
fn extract_json_int(text : String, key : String) -> Int? {
  let start = text.find(key)
  match start {
    None => None
    Some(s) => {
      let after = s + key.length()
      let mut num_str = ""
      let mut i = after
      while i < text.length() && text[i] >= 0x30 && text[i] <= 0x39 {
        num_str = num_str + text[i].to_string()
        i = i + 1
      }
      if num_str == "" {
        None
      } else {
        Some(@string.parse_int(num_str) catch { _ => return None })
      }
    }
  }
}
