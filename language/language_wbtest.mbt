///|
test "LanguageId::to_int" {
  @debug.assert_eq(LanguageId::C.to_int(), 0)
  @debug.assert_eq(LanguageId::Cpp.to_int(), 1)
  @debug.assert_eq(LanguageId::Rust.to_int(), 2)
  @debug.assert_eq(LanguageId::Python.to_int(), 3)
  @debug.assert_eq(LanguageId::JavaScript.to_int(), 4)
  @debug.assert_eq(LanguageId::TypeScript.to_int(), 5)
  @debug.assert_eq(LanguageId::Go.to_int(), 6)
  @debug.assert_eq(LanguageId::Java.to_int(), 7)
  @debug.assert_eq(LanguageId::MoonBit.to_int(), 9)
  @debug.assert_eq(LanguageId::CSharp.to_int(), 8)
}

///|
test "LanguageId::to_name" {
  @debug.assert_eq(LanguageId::C.to_name(), "c")
  @debug.assert_eq(LanguageId::Cpp.to_name(), "cpp")
  @debug.assert_eq(LanguageId::Rust.to_name(), "rust")
  @debug.assert_eq(LanguageId::Python.to_name(), "python")
  @debug.assert_eq(LanguageId::JavaScript.to_name(), "javascript")
  @debug.assert_eq(LanguageId::TypeScript.to_name(), "typescript")
  @debug.assert_eq(LanguageId::Go.to_name(), "go")
  @debug.assert_eq(LanguageId::Java.to_name(), "java")
  @debug.assert_eq(LanguageId::MoonBit.to_name(), "moonbit")
  @debug.assert_eq(LanguageId::CSharp.to_name(), "csharp")
}

///|
test "LanguageId::from_name" {
  @debug.assert_eq(LanguageId::from_name("c"), Some(LanguageId::C))
  @debug.assert_eq(LanguageId::from_name("cpp"), Some(LanguageId::Cpp))
  @debug.assert_eq(LanguageId::from_name("rust"), Some(LanguageId::Rust))
  @debug.assert_eq(LanguageId::from_name("python"), Some(LanguageId::Python))
  @debug.assert_eq(
    LanguageId::from_name("javascript"),
    Some(LanguageId::JavaScript),
  )
  @debug.assert_eq(
    LanguageId::from_name("typescript"),
    Some(LanguageId::TypeScript),
  )
  @debug.assert_eq(LanguageId::from_name("go"), Some(LanguageId::Go))
  @debug.assert_eq(LanguageId::from_name("java"), Some(LanguageId::Java))
  @debug.assert_eq(LanguageId::from_name("csharp"), Some(LanguageId::CSharp))
  @debug.assert_eq(LanguageId::from_name("moonbit"), Some(LanguageId::MoonBit))
  @debug.assert_eq(LanguageId::from_name("unknown"), None)
}

///|
test "LanguageId::from_name aliases" {
  @debug.assert_eq(LanguageId::from_name("js"), Some(LanguageId::JavaScript))
  @debug.assert_eq(LanguageId::from_name("ts"), Some(LanguageId::TypeScript))
  @debug.assert_eq(LanguageId::from_name("golang"), Some(LanguageId::Go))
  @debug.assert_eq(LanguageId::from_name("c#"), Some(LanguageId::CSharp))
  @debug.assert_eq(LanguageId::from_name("cs"), Some(LanguageId::CSharp))
  @debug.assert_eq(LanguageId::from_name("mbt"), Some(LanguageId::MoonBit))
}

///|
test "detect_language_from_extension" {
  @debug.assert_eq(
    detect_language_from_extension("main.c"),
    Some(LanguageId::C),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.h"),
    Some(LanguageId::C),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.cpp"),
    Some(LanguageId::Cpp),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.rs"),
    Some(LanguageId::Rust),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.py"),
    Some(LanguageId::Python),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.js"),
    Some(LanguageId::JavaScript),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.ts"),
    Some(LanguageId::TypeScript),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.go"),
    Some(LanguageId::Go),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.java"),
    Some(LanguageId::Java),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.cs"),
    Some(LanguageId::CSharp),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.mbt"),
    Some(LanguageId::MoonBit),
  )
  @debug.assert_eq(detect_language_from_extension("unknown.xyz"), None)
}

///|
test "detect_language_from_extension jsx/tsx" {
  @debug.assert_eq(
    detect_language_from_extension("component.jsx"),
    Some(LanguageId::JavaScript),
  )
  @debug.assert_eq(
    detect_language_from_extension("component.tsx"),
    Some(LanguageId::TypeScript),
  )
}

///|
test "detect_language_from_extension cxx/hpp" {
  @debug.assert_eq(
    detect_language_from_extension("main.cxx"),
    Some(LanguageId::Cpp),
  )
  @debug.assert_eq(
    detect_language_from_extension("main.hpp"),
    Some(LanguageId::Cpp),
  )
}

///|
test "Point construction" {
  let p = Point::new(5, 10)
  @debug.assert_eq(p.row, 5)
  @debug.assert_eq(p.col, 10)
}

///|
test "Range construction" {
  let start = Point::new(1, 2)
  let end = Point::new(3, 4)
  let r = Range::new(start, end)
  @debug.assert_eq(r.start.row, 1)
  @debug.assert_eq(r.start.col, 2)
  @debug.assert_eq(r.end.row, 3)
  @debug.assert_eq(r.end.col, 4)
}

///|
test "Capture construction" {
  let r = Range::new(Point::new(0, 0), Point::new(1, 5))
  let cap = Capture::new("func", "function", r)
  @debug.assert_eq(cap.name, "func")
  @debug.assert_eq(cap.kind, "function")
  @debug.assert_eq(cap.range.start.row, 0)
  @debug.assert_eq(cap.range.end.col, 5)
}

///|
test "QueryMatch empty captures" {
  let m = QueryMatch::new(0, [])
  @debug.assert_eq(m.pattern_index, 0)
  @debug.assert_eq(m.captures.length(), 0)
}

///|
test "QueryMatch with captures" {
  let cap1 = Capture::new(
    "a",
    "identifier",
    Range::new(Point::new(0, 0), Point::new(0, 3)),
  )
  let cap2 = Capture::new(
    "b",
    "string",
    Range::new(Point::new(0, 5), Point::new(0, 10)),
  )
  let m = QueryMatch::new(1, [cap1, cap2])
  @debug.assert_eq(m.pattern_index, 1)
  @debug.assert_eq(m.captures.length(), 2)
  @debug.assert_eq(m.captures[0].name, "a")
  @debug.assert_eq(m.captures[1].kind, "string")
}
