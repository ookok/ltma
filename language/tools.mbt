///|
/// Agent tools for language parsing — integrate with the ToolRegistry.

///|
/// Parse code and return AST as JSON string.
pub fn parse_code_tool(code : String, lang_name : String) -> String {
  let lang_id = LanguageId::from_name(lang_name)
  match lang_id {
    None => "{\"error\":\"unsupported language: " + lang_name + "\"}"
    Some(lid) =>
      match parse_code(code, lid.to_int()) {
        None => "{\"error\":\"parse failed\"}"
        Some(tree) => {
          let json = tree_to_json(tree, 5)
          free_tree(tree)
          @core.json_encode(json)
        }
      }
  }
}

///|
/// Query a syntax tree and return captures.
pub fn query_code_tool(
  code : String,
  lang_name : String,
  pattern : String,
) -> String {
  let lang_id = LanguageId::from_name(lang_name)
  match lang_id {
    None => "{\"error\":\"unsupported language\"}"
    Some(lid) => {
      let lang_ptr = _ts_language_from_id(lid.to_int())
      if lang_ptr == 0L {
        return "{\"error\":\"language grammar not available\"}"
      }
      match parse_code(code, lid.to_int()) {
        None => "{\"error\":\"parse failed\"}"
        Some(tree) => {
          let root_data = _ts_root_node(tree.ptr)
          let root = SyntaxNode::new(root_data, tree)
          let query = QueryHandle::new(lang_ptr)
          if !query.compile(pattern) {
            free_tree(tree)
            return "{\"error\":\"invalid query pattern\"}"
          }
          let matches = query_matches(query, root)
          query.free()
          free_tree(tree)
          let match_list : Array[@core.JsonValue] = []
          for m in matches {
            let cap_list : Array[@core.JsonValue] = []
            for c in m.captures {
              cap_list.push(
                @core.JsonValue::object(
                  Map([
                    ("name", @core.JsonValue::string(c.name)),
                    ("type", @core.JsonValue::string(c.kind)),
                    ("start_row", @core.JsonValue::int(c.range.start.row)),
                    ("start_col", @core.JsonValue::int(c.range.start.col)),
                    ("end_row", @core.JsonValue::int(c.range.end.row)),
                    ("end_col", @core.JsonValue::int(c.range.end.col)),
                  ]),
                ),
              )
            }
            match_list.push(
              @core.JsonValue::object(
                Map([
                  ("pattern", @core.JsonValue::int(m.pattern_index)),
                  ("captures", @core.JsonValue::array(cap_list)),
                ]),
              ),
            )
          }
          @core.json_encode(
            @core.JsonValue::object(
              Map([("matches", @core.JsonValue::array(match_list))]),
            ),
          )
        }
      }
    }
  }
}

///|
/// Create a parse_code tool entry for the ToolRegistry.
pub fn make_parse_tool() -> @tool.ToolEntry {
  @tool.ToolEntry::create(
    @core.ToolDefinition::create(
      "parse_code", "Parse source code and return AST as JSON. Args: {code, lang}",
      "{type:object,properties:{code:{type:string},lang:{type:string}}}", false,
    ),
    fn(args : String) -> String {
      let parts = args.split("|").to_array()
      let code = parts[0].to_owned()
      let lang = if parts.length() > 1 {
        parts[1].to_owned()
      } else {
        "moonbit"
      }
      parse_code_tool(code, lang)
    },
  )
}

///|
/// Create a query_code tool entry for the ToolRegistry.
pub fn make_query_tool() -> @tool.ToolEntry {
  @tool.ToolEntry::create(
    @core.ToolDefinition::create(
      "query_code", "Query AST with tree-sitter pattern. Args: {code, lang, pattern}",
      "{type:object,properties:{code:{type:string},lang:{type:string},pattern:{type:string}}}",
      false,
    ),
    fn(args : String) -> String {
      let parts = args.split("|").to_array()
      if parts.length() < 3 {
        return "{\"error\":\"need code|lang|pattern\"}"
      }
      let code = parts[0].to_owned()
      let lang = parts[1].to_owned()
      let pattern = parts[2].to_owned()
      query_code_tool(code, lang, pattern)
    },
  )
}
