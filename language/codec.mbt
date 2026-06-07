///|
/// AST serialization — convert syntax tree nodes to structured data.

///|
/// Serialize a syntax node and its children to a JSON value.
pub fn node_to_json(node : SyntaxNode, depth : Int) -> @core.JsonValue {
  if depth <= 0 {
    return @core.JsonValue::null()
  }
  let kind = _ts_node_type(node.data)
  let kind_str = @utf8.decode_lossy(kind)
  let is_named = _ts_node_is_named(node.data)
  let has_err = _ts_node_has_error(node.data)
  let start_row = _ts_node_start_row(node.data)
  let start_col = _ts_node_start_col(node.data)
  let end_row = _ts_node_end_row(node.data)
  let end_col = _ts_node_end_col(node.data)
  let child_count = _ts_node_child_count(node.data)

  let children : Array[@core.JsonValue] = []
  if depth > 1 {
    for i = 0; i < child_count; i = i + 1 {
      let child_data = _ts_node_child(node.data, i)
      let child_node = SyntaxNode::new(child_data, node.tree)
      children.push(node_to_json(child_node, depth - 1))
    }
  }

  let entries : Array[(String, @core.JsonValue)] = [
    ("type", @core.JsonValue::string(kind_str)),
    ("named", @core.JsonValue::bool(is_named)),
    ("error", @core.JsonValue::bool(has_err)),
    (
      "start",
      @core.JsonValue::object(
        Map([
          ("row", @core.JsonValue::int(start_row)),
          ("col", @core.JsonValue::int(start_col)),
        ]),
      ),
    ),
    (
      "end",
      @core.JsonValue::object(
        Map([
          ("row", @core.JsonValue::int(end_row)),
          ("col", @core.JsonValue::int(end_col)),
        ]),
      ),
    ),
  ]
  if children.length() > 0 {
    entries.push(("children", @core.JsonValue::array(children)))
  }
  @core.JsonValue::object(Map(entries))
}

///|
/// Serialize entire tree to JSON with configurable depth.
pub fn tree_to_json(tree : SyntaxTree, depth : Int) -> @core.JsonValue {
  let root_data = _ts_root_node(tree.ptr)
  let root = SyntaxNode::new(root_data, tree)
  node_to_json(root, depth)
}

///|
/// Get the source text for a syntax node from the original code.
pub fn node_text(code : String, node : SyntaxNode) -> String {
  let start = _ts_node_start_byte(node.data)
  let end = _ts_node_end_byte(node.data)
  code[start:end].to_owned()
}
