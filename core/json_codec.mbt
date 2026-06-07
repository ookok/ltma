///|
/// JSON codec — encode/decode structured data without external dependencies.

///|
/// JsonValue — a simple JSON value representation.
pub enum JsonValue {
  JNull
  JBool(Bool)
  JNumber(Int)
  JString(String)
  JArray(Array[JsonValue])
  JObject(Map[String, JsonValue])
}

///|
/// Encode a JsonValue to a JSON string.
pub fn json_encode(value : JsonValue) -> String {
  match value {
    JsonValue::JNull => "null"
    JsonValue::JBool(b) => if b { "true" } else { "false" }
    JsonValue::JNumber(n) => n.to_string()
    JsonValue::JString(s) => "\"" + s + "\""
    JsonValue::JArray(arr) => {
      let mut parts = "["
      let mut first = true
      for item in arr {
        if first {
          first = false
        } else {
          parts = parts + ","
        }
        parts = parts + json_encode(item)
      }
      parts + "]"
    }
    JsonValue::JObject(obj) => {
      let mut parts = "{"
      let mut first = true
      for k, v in obj {
        if first {
          first = false
        } else {
          parts = parts + ","
        }
        parts = parts + "\"" + k + "\":"
        parts = parts + json_encode(v)
      }
      parts + "}"
    }
  }
}

///|
pub fn JsonValue::null() -> JsonValue {
  JNull
}

///|
pub fn JsonValue::bool(b : Bool) -> JsonValue {
  JBool(b)
}

///|
pub fn JsonValue::int(n : Int) -> JsonValue {
  JNumber(n)
}

///|
pub fn JsonValue::string(s : String) -> JsonValue {
  JString(s)
}

///|
pub fn JsonValue::array(arr : Array[JsonValue]) -> JsonValue {
  JArray(arr)
}

///|
pub fn JsonValue::object(obj : Map[String, JsonValue]) -> JsonValue {
  JObject(obj)
}
