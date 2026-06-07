#include <moonbit.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#pragma comment(lib, "tree-sitter")

#include <tree_sitter/api.h>

// ---- Helper: pack/unpack TSNode from Bytes ----
#define TS_NODE_SIZE 32

static void pack_node(uint8_t* dest, TSNode node) {
  memcpy(dest, &node, TS_NODE_SIZE);
}

static TSNode unpack_node(const uint8_t* src) {
  TSNode node;
  memcpy(&node, src, TS_NODE_SIZE);
  return node;
}

// ---- Parser ----

MOONBIT_FFI_EXPORT
void* ts_parser_new_wrapper(void) {
  return (void*)ts_parser_new();
}

MOONBIT_FFI_EXPORT
void ts_parser_free_wrapper(void* parser) {
  ts_parser_delete((TSParser*)parser);
}

MOONBIT_FFI_EXPORT
int ts_parser_set_language_wrapper(void* parser, void* language) {
  return ts_parser_set_language((TSParser*)parser, (const TSLanguage*)language) ? 1 : 0;
}

// ---- Parse ----

MOONBIT_FFI_EXPORT
void* ts_parse_string_wrapper(void* parser, const char* code, int len) {
  return (void*)ts_parser_parse_string((TSParser*)parser, NULL, code, (uint32_t)len);
}

// ---- Tree ----

MOONBIT_FFI_EXPORT
void ts_tree_free_wrapper(void* tree) {
  ts_tree_delete((TSTree*)tree);
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_root_node_wrapper(void* tree) {
  TSNode root = ts_tree_root_node((const TSTree*)tree);
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(TS_NODE_SIZE, 0);
  pack_node(bytes, root);
  return (moonbit_bytes_t)bytes;
}

// ---- Node ----

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_node_child_wrapper(const uint8_t* node_bytes, int index) {
  TSNode node = unpack_node(node_bytes);
  TSNode child = ts_node_child(node, (uint32_t)index);
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(TS_NODE_SIZE, 0);
  pack_node(bytes, child);
  return (moonbit_bytes_t)bytes;
}

MOONBIT_FFI_EXPORT
int ts_node_child_count_wrapper(const uint8_t* node_bytes) {
  return (int)ts_node_child_count(unpack_node(node_bytes));
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_node_type_wrapper(const uint8_t* node_bytes) {
  const char* type = ts_node_type(unpack_node(node_bytes));
  int len = strlen(type);
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(len, 0);
  memcpy(bytes, type, len);
  return (moonbit_bytes_t)bytes;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_node_parent_wrapper(const uint8_t* node_bytes) {
  TSNode parent = ts_node_parent(unpack_node(node_bytes));
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(TS_NODE_SIZE, 0);
  pack_node(bytes, parent);
  return (moonbit_bytes_t)bytes;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_node_next_sibling_wrapper(const uint8_t* node_bytes) {
  TSNode sib = ts_node_next_sibling(unpack_node(node_bytes));
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(TS_NODE_SIZE, 0);
  pack_node(bytes, sib);
  return (moonbit_bytes_t)bytes;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_node_prev_sibling_wrapper(const uint8_t* node_bytes) {
  TSNode sib = ts_node_prev_sibling(unpack_node(node_bytes));
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(TS_NODE_SIZE, 0);
  pack_node(bytes, sib);
  return (moonbit_bytes_t)bytes;
}

MOONBIT_FFI_EXPORT
int ts_node_start_row_wrapper(const uint8_t* node_bytes) {
  return (int)ts_node_start_point(unpack_node(node_bytes)).row;
}

MOONBIT_FFI_EXPORT
int ts_node_start_col_wrapper(const uint8_t* node_bytes) {
  return (int)ts_node_start_point(unpack_node(node_bytes)).column;
}

MOONBIT_FFI_EXPORT
int ts_node_end_row_wrapper(const uint8_t* node_bytes) {
  return (int)ts_node_end_point(unpack_node(node_bytes)).row;
}

MOONBIT_FFI_EXPORT
int ts_node_end_col_wrapper(const uint8_t* node_bytes) {
  return (int)ts_node_end_point(unpack_node(node_bytes)).column;
}

MOONBIT_FFI_EXPORT
int ts_node_start_byte_wrapper(const uint8_t* node_bytes) {
  return (int)ts_node_start_byte(unpack_node(node_bytes));
}

MOONBIT_FFI_EXPORT
int ts_node_end_byte_wrapper(const uint8_t* node_bytes) {
  return (int)ts_node_end_byte(unpack_node(node_bytes));
}

MOONBIT_FFI_EXPORT
int ts_node_is_named_wrapper(const uint8_t* node_bytes) {
  return ts_node_is_named(unpack_node(node_bytes)) ? 1 : 0;
}

MOONBIT_FFI_EXPORT
int ts_node_has_error_wrapper(const uint8_t* node_bytes) {
  return ts_node_has_error(unpack_node(node_bytes)) ? 1 : 0;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_node_named_child_wrapper(const uint8_t* node_bytes, int index) {
  TSNode child = ts_node_named_child(unpack_node(node_bytes), (uint32_t)index);
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(TS_NODE_SIZE, 0);
  pack_node(bytes, child);
  return (moonbit_bytes_t)bytes;
}

MOONBIT_FFI_EXPORT
int ts_node_named_child_count_wrapper(const uint8_t* node_bytes) {
  return (int)ts_node_named_child_count(unpack_node(node_bytes));
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_node_string_wrapper(const uint8_t* node_bytes) {
  char* str = ts_node_string(unpack_node(node_bytes));
  int len = strlen(str);
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(len, 0);
  memcpy(bytes, str, len);
  free(str);
  return (moonbit_bytes_t)bytes;
}

// ---- Language grammars (extern declarations, linked from grammar files) ----

extern void* tree_sitter_c(void);
extern void* tree_sitter_cpp(void);
extern void* tree_sitter_rust(void);
extern void* tree_sitter_python(void);
extern void* tree_sitter_javascript(void);
extern void* tree_sitter_typescript(void);
extern void* tree_sitter_go(void);
extern void* tree_sitter_java(void);
extern void* tree_sitter_moonbit(void);

MOONBIT_FFI_EXPORT
void* ts_language_from_id(int lang_id) {
  switch (lang_id) {
    case 0: return tree_sitter_c();
    case 1: return tree_sitter_cpp();
    case 2: return tree_sitter_rust();
    case 3: return tree_sitter_python();
    case 4: return tree_sitter_javascript();
    case 5: return tree_sitter_typescript();
    case 6: return tree_sitter_go();
    case 7: return tree_sitter_java();
    case 8: return tree_sitter_moonbit();
    default: return NULL;
  }
}

// ---- Query ----

MOONBIT_FFI_EXPORT
void* ts_query_new_wrapper(void* language, const char* pattern, int len) {
  uint32_t error_offset = 0;
  TSQueryError error_type = TSQueryErrorNone;
  return (void*)ts_query_new((const TSLanguage*)language, pattern, (uint32_t)len,
                             &error_offset, &error_type);
}

MOONBIT_FFI_EXPORT
void ts_query_free_wrapper(void* query) {
  ts_query_delete((TSQuery*)query);
}

MOONBIT_FFI_EXPORT
void* ts_query_cursor_new_wrapper(void) {
  return (void*)ts_query_cursor_new();
}

MOONBIT_FFI_EXPORT
void ts_query_cursor_free_wrapper(void* cursor) {
  ts_query_cursor_delete((TSQueryCursor*)cursor);
}

MOONBIT_FFI_EXPORT
int ts_query_cursor_exec_wrapper(void* cursor, void* query, const uint8_t* node_bytes) {
  ts_query_cursor_exec((TSQueryCursor*)cursor, (const TSQuery*)query, unpack_node(node_bytes));
  return 1;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t ts_query_cursor_next_match_wrapper(void* cursor, void* query) {
  TSQueryMatch match;
  if (!ts_query_cursor_next_match((TSQueryCursor*)cursor, &match)) {
    return moonbit_make_bytes(0, 0);
  }
  // Build JSON: { "pattern": N, "captures": [ { "name": "...", "type": "...",
  //   "start_row": N, "start_col": N, "end_row": N, "end_col": N }, ... ] }
  char buf[8192];
  int pos = snprintf(buf, sizeof(buf), "{\"pattern\":%d,\"captures\":[",
                     (int)match.pattern_index);
  for (uint32_t i = 0; i < match.capture_count; i++) {
    TSQueryCapture cap = match.captures[i];
    uint32_t name_len = 0;
    const char* name = ts_query_capture_name_for_id((const TSQuery*)query,
                                                     cap.index, &name_len);
    TSNode node = cap.node;
    TSPoint start = ts_node_start_point(node);
    TSPoint end = ts_node_end_point(node);
    if (i > 0) buf[pos++] = ',';
    pos += snprintf(buf + pos, sizeof(buf) - pos,
      "{\"name\":\"%.*s\",\"type\":\"%s\","
      "\"start_row\":%d,\"start_col\":%d,\"end_row\":%d,\"end_col\":%d}",
      (int)name_len, name, ts_node_type(node),
      (int)start.row, (int)start.column, (int)end.row, (int)end.column);
  }
  buf[pos++] = ']'; buf[pos++] = '}'; buf[pos] = '\0';
  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(pos, 0);
  memcpy(bytes, buf, pos);
  return (moonbit_bytes_t)bytes;
}
