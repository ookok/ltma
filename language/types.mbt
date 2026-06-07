///|
/// Value types for tree-sitter syntax trees.
/// SyntaxNode stores packed TSNode bytes (32 bytes) and keeps SyntaxTree alive.

///|
/// A parsed syntax tree. Holds the C TSTree pointer (Int64).
pub struct SyntaxTree {
  ptr : Int64
}

///|
pub fn SyntaxTree::new(ptr : Int64) -> SyntaxTree {
  { ptr, }
}

///|
/// A node in the syntax tree. Stores packed TSNode bytes + tree reference.
pub struct SyntaxNode {
  data : Bytes
  tree : SyntaxTree
}

///|
pub fn SyntaxNode::new(data : Bytes, tree : SyntaxTree) -> SyntaxNode {
  { data, tree }
}

///|
/// A point in source code (row and column, both 0-based).
pub struct Point {
  row : Int
  col : Int
}

///|
pub fn Point::new(row : Int, col : Int) -> Point {
  { row, col }
}

///|
/// A range in source code.
pub struct Range {
  start : Point
  end : Point
}

///|
pub fn Range::new(start : Point, end : Point) -> Range {
  { start, end }
}

///|
/// A capture from a query match.
pub struct Capture {
  name : String
  kind : String
  range : Range
}

///|
pub fn Capture::new(name : String, kind : String, range : Range) -> Capture {
  { name, kind, range }
}

///|
/// A query match result.
pub struct QueryMatch {
  pattern_index : Int
  captures : Array[Capture]
}

///|
pub fn QueryMatch::new(
  pattern_index : Int,
  captures : Array[Capture],
) -> QueryMatch {
  { pattern_index, captures }
}
