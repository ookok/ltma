///|
/// Language registry — maps LanguageId to tree-sitter grammar pointers.

///|
/// Supported programming languages.
pub enum LanguageId {
  C
  Cpp
  Rust
  Python
  JavaScript
  TypeScript
  Go
  Java
  CSharp
  MoonBit
} derive(Eq, Debug)

///|
pub fn LanguageId::to_int(self : LanguageId) -> Int {
  match self {
    LanguageId::C => 0
    LanguageId::Cpp => 1
    LanguageId::Rust => 2
    LanguageId::Python => 3
    LanguageId::JavaScript => 4
    LanguageId::TypeScript => 5
    LanguageId::Go => 6
    LanguageId::Java => 7
    LanguageId::CSharp => 8
    LanguageId::MoonBit => 9
  }
}

///|
pub fn LanguageId::to_name(self : LanguageId) -> String {
  match self {
    LanguageId::C => "c"
    LanguageId::Cpp => "cpp"
    LanguageId::Rust => "rust"
    LanguageId::Python => "python"
    LanguageId::JavaScript => "javascript"
    LanguageId::TypeScript => "typescript"
    LanguageId::Go => "go"
    LanguageId::Java => "java"
    LanguageId::CSharp => "csharp"
    LanguageId::MoonBit => "moonbit"
  }
}

///|
pub fn LanguageId::from_name(name : String) -> LanguageId? {
  match name {
    "c" => Some(LanguageId::C)
    "cpp" => Some(LanguageId::Cpp)
    "rust" => Some(LanguageId::Rust)
    "python" => Some(LanguageId::Python)
    "javascript" | "js" => Some(LanguageId::JavaScript)
    "typescript" | "ts" => Some(LanguageId::TypeScript)
    "go" | "golang" => Some(LanguageId::Go)
    "java" => Some(LanguageId::Java)
    "csharp" | "c#" | "cs" => Some(LanguageId::CSharp)
    "moonbit" | "mbt" => Some(LanguageId::MoonBit)
    _ => None
  }
}

///|
/// Detect language from file extension.
pub fn detect_language_from_extension(path : String) -> LanguageId? {
  if path.has_suffix(".c") || path.has_suffix(".h") {
    Some(LanguageId::C)
  } else if path.has_suffix(".cpp") ||
    path.has_suffix(".cc") ||
    path.has_suffix(".cxx") ||
    path.has_suffix(".hpp") {
    Some(LanguageId::Cpp)
  } else if path.has_suffix(".rs") {
    Some(LanguageId::Rust)
  } else if path.has_suffix(".py") {
    Some(LanguageId::Python)
  } else if path.has_suffix(".js") || path.has_suffix(".jsx") {
    Some(LanguageId::JavaScript)
  } else if path.has_suffix(".ts") || path.has_suffix(".tsx") {
    Some(LanguageId::TypeScript)
  } else if path.has_suffix(".go") {
    Some(LanguageId::Go)
  } else if path.has_suffix(".java") {
    Some(LanguageId::Java)
  } else if path.has_suffix(".cs") {
    Some(LanguageId::CSharp)
  } else if path.has_suffix(".mbt") {
    Some(LanguageId::MoonBit)
  } else {
    None
  }
}
