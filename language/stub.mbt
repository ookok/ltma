///|
/// Raw FFI declarations for tree-sitter C library.
/// All extern functions are gated to native target in moon.pkg.

// ---- Parser ----

///|
extern "c" fn _ts_parser_new() -> Int64 = "ts_parser_new_wrapper"

///|
#external(parser)
extern "c" fn _ts_parser_free(parser : Int64) = "ts_parser_free_wrapper"

///|
#borrow(parser)
extern "c" fn _ts_parser_set_language(parser : Int64, lang : Int64) -> Bool = "ts_parser_set_language_wrapper"

// ---- Parse ----

///|
#borrow(parser)
#owned(code)
extern "c" fn _ts_parse_string(
  parser : Int64,
  code : Bytes,
  len : Int,
) -> Int64 = "ts_parse_string_wrapper"

// ---- Tree ----

///|
#external(tree)
extern "c" fn _ts_tree_free(tree : Int64) = "ts_tree_free_wrapper"

///|
#external(tree)
extern "c" fn _ts_root_node(tree : Int64) -> Bytes = "ts_root_node_wrapper"

// ---- Node navigation ----

///|
#borrow(node)
extern "c" fn _ts_node_child(node : Bytes, index : Int) -> Bytes = "ts_node_child_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_child_count(node : Bytes) -> Int = "ts_node_child_count_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_type(node : Bytes) -> Bytes = "ts_node_type_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_parent(node : Bytes) -> Bytes = "ts_node_parent_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_next_sibling(node : Bytes) -> Bytes = "ts_node_next_sibling_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_prev_sibling(node : Bytes) -> Bytes = "ts_node_prev_sibling_wrapper"

// ---- Node properties ----

///|
#borrow(node)
extern "c" fn _ts_node_start_row(node : Bytes) -> Int = "ts_node_start_row_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_start_col(node : Bytes) -> Int = "ts_node_start_col_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_end_row(node : Bytes) -> Int = "ts_node_end_row_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_end_col(node : Bytes) -> Int = "ts_node_end_col_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_start_byte(node : Bytes) -> Int = "ts_node_start_byte_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_end_byte(node : Bytes) -> Int = "ts_node_end_byte_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_is_named(node : Bytes) -> Bool = "ts_node_is_named_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_has_error(node : Bytes) -> Bool = "ts_node_has_error_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_named_child(node : Bytes, index : Int) -> Bytes = "ts_node_named_child_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_named_child_count(node : Bytes) -> Int = "ts_node_named_child_count_wrapper"

///|
#borrow(node)
extern "c" fn _ts_node_string(node : Bytes) -> Bytes = "ts_node_string_wrapper"

// ---- Language ----

///|
extern "c" fn _ts_language_from_id(lang_id : Int) -> Int64 = "ts_language_from_id"

// ---- Query ----

///|
#borrow(lang)
#owned(pattern)
extern "c" fn _ts_query_new(lang : Int64, pattern : Bytes, len : Int) -> Int64 = "ts_query_new_wrapper"

///|
#external(query)
extern "c" fn _ts_query_free(query : Int64) = "ts_query_free_wrapper"

///|
extern "c" fn _ts_query_cursor_new() -> Int64 = "ts_query_cursor_new_wrapper"

///|
#external(cursor)
extern "c" fn _ts_query_cursor_free(cursor : Int64) = "ts_query_cursor_free_wrapper"

///|
#borrow(cursor)
#borrow(query)
#borrow(node)
extern "c" fn _ts_query_cursor_exec(
  cursor : Int64,
  query : Int64,
  node : Bytes,
) -> Bool = "ts_query_cursor_exec_wrapper"

///|
#borrow(cursor)
#borrow(query)
extern "c" fn _ts_query_cursor_next_match(
  cursor : Int64,
  query : Int64,
) -> Bytes = "ts_query_cursor_next_match_wrapper"
