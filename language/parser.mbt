///|
/// ParserHandle — wraps a tree-sitter TSParser with closure-based Handle pattern.
/// Follows the same pattern as LLMProviderHandle and AgentHandle.

///|
/// ParserHandle — parser instance with language support.
pub struct ParserHandle {
  ptr : Int64
}

///|
pub fn ParserHandle::new() -> ParserHandle {
  let ptr = _ts_parser_new()
  { ptr, }
}

///|
pub fn ParserHandle::free(self : ParserHandle) -> Unit {
  _ts_parser_free(self.ptr)
}

///|
/// Set the language for this parser. Returns false if language is not available.
pub fn ParserHandle::set_language(self : ParserHandle, lang_id : Int) -> Bool {
  let lang_ptr = _ts_language_from_id(lang_id)
  if lang_ptr == 0L {
    false
  } else {
    _ts_parser_set_language(self.ptr, lang_ptr)
  }
}

///|
/// Parse source code into a syntax tree.
pub fn ParserHandle::parse(self : ParserHandle, code : String) -> SyntaxTree? {
  let bytes = @utf8.encode(code)
  let tree_ptr = _ts_parse_string(self.ptr, bytes, bytes.length())
  if tree_ptr == 0L {
    None
  } else {
    Some(SyntaxTree::new(tree_ptr))
  }
}

///|
/// Create a parser, set language, and parse in one call.
pub fn parse_code(code : String, lang_id : Int) -> SyntaxTree? {
  let parser = ParserHandle::new()
  if !parser.set_language(lang_id) {
    parser.free()
    return None
  }
  let tree = parser.parse(code)
  parser.free()
  tree
}

///|
/// Free a syntax tree (releases C TSTree memory).
pub fn free_tree(tree : SyntaxTree) -> Unit {
  _ts_tree_free(tree.ptr)
}
