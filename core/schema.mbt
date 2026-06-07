///|
/// Schema validation — message and tool call contract validation.

///|
/// SchemaType — supported schema types.
pub enum SchemaType {
  String
  Int
  Bool
  Array
  Object
}

///|
/// FieldSchema — schema for a single field.
pub struct FieldSchema {
  name : String
  typ : SchemaType
  required : Bool
  description : String
}

///|
pub fn FieldSchema::new(
  name : String,
  typ : SchemaType,
  required : Bool,
  description : String,
) -> FieldSchema {
  { name, typ, required, description }
}

///|
/// MessageSchema — schema that a message must conform to.
pub struct MessageSchema {
  kind : String
  fields : Array[FieldSchema]
}

///|
pub fn MessageSchema::new(
  kind : String,
  fields : Array[FieldSchema],
) -> MessageSchema {
  { kind, fields }
}

///|
pub fn MessageSchema::validate(
  self : MessageSchema,
  msg : Message,
) -> Array[String] {
  let errors : Array[String] = []
  for field in self.fields {
    if field.required && field.name == "content" {
      if !msg.is_text() {
        errors.push("missing required field: " + field.name)
      }
    }
  }
  errors
}

///|
/// ToolCallSchema — schema a tool call must conform to.
pub struct ToolCallSchema {
  tool_name : String
  params : Array[FieldSchema]
}

///|
pub fn ToolCallSchema::new(
  tool_name : String,
  params : Array[FieldSchema],
) -> ToolCallSchema {
  { tool_name, params }
}

///|
pub fn ToolCallSchema::validate(
  self : ToolCallSchema,
  call : ToolCall,
) -> Array[String] {
  let errors : Array[String] = []
  if call.name != self.tool_name {
    errors.push("expected tool '\{self.tool_name}' but got '\{call.name}'")
  }
  errors
}

///|
/// SchemaRegistry — stores and resolves message and tool schemas.
pub struct SchemaRegistry {
  message_schemas : Map[String, MessageSchema]
  tool_schemas : Map[String, ToolCallSchema]
}

///|
pub fn SchemaRegistry::new() -> SchemaRegistry {
  { message_schemas: Map([]), tool_schemas: Map([]) }
}

///|
pub fn SchemaRegistry::register_message(
  self : SchemaRegistry,
  schema : MessageSchema,
) -> Unit {
  self.message_schemas[schema.kind] = schema
}

///|
pub fn SchemaRegistry::register_tool(
  self : SchemaRegistry,
  schema : ToolCallSchema,
) -> Unit {
  self.tool_schemas[schema.tool_name] = schema
}

///|
pub fn SchemaRegistry::validate_message(
  self : SchemaRegistry,
  kind : String,
  msg : Message,
) -> Array[String] {
  match self.message_schemas.get(kind) {
    Some(schema) => schema.validate(msg)
    None => ["no schema registered for kind: " + kind]
  }
}

///|
pub fn SchemaRegistry::validate_tool_call(
  self : SchemaRegistry,
  call : ToolCall,
) -> Array[String] {
  match self.tool_schemas.get(call.name) {
    Some(schema) => schema.validate(call)
    None => ["no schema registered for tool: " + call.name]
  }
}
