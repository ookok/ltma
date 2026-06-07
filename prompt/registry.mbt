///|
/// Prompt Registry — versioned prompt templates with variable injection.

///|
/// PromptTemplate — a named, versioned prompt with variables.
pub struct PromptTemplate {
  name : String
  version : String
  template : String
  variables : Array[String]
  description : String
}

///|
pub fn PromptTemplate::new(
  name : String,
  version : String,
  template : String,
  variables : Array[String],
  description : String,
) -> PromptTemplate {
  { name, version, template, variables, description }
}

///|
pub fn PromptTemplate::render(
  self : PromptTemplate,
  values : Map[String, String],
) -> String? {
  let mut result = self.template
  for var in self.variables {
    match values.get(var) {
      Some(val) => result = result.replace(old="{{" + var + "}}", new=val)
      None => return None
    }
  }
  Some(result)
}

///|
/// PromptRegistry — versioned template storage.
pub struct PromptRegistry {
  entries : Map[String, PromptTemplate]
}

///|
pub fn PromptRegistry::new() -> PromptRegistry {
  { entries: Map([]) }
}

///|
pub fn PromptRegistry::register(
  self : PromptRegistry,
  tpl : PromptTemplate,
) -> Unit {
  let key = tpl.name + "@" + tpl.version
  self.entries[key] = tpl
}

///|
pub fn PromptRegistry::resolve(
  self : PromptRegistry,
  name : String,
  version : String,
) -> PromptTemplate? {
  self.entries.get(name + "@" + version)
}

///|
pub fn PromptRegistry::latest(
  self : PromptRegistry,
  name : String,
) -> PromptTemplate? {
  let mut latest_tpl : PromptTemplate? = None
  let mut latest_ver : String? = None
  for key, tpl in self.entries {
    let prefix = name + "@"
    if key.starts_with(prefix) {
      let ver : String = key.sub(start=prefix.length()).to_owned()
      match latest_ver {
        Some(lv) =>
          if ver > lv {
            latest_ver = Some(ver)
            latest_tpl = Some(tpl)
          }
        None => {
          latest_ver = Some(ver)
          latest_tpl = Some(tpl)
        }
      }
    }
  }
  latest_tpl
}

///|
pub fn PromptRegistry::list(
  self : PromptRegistry,
  name : String,
) -> Array[PromptTemplate] {
  let result : Array[PromptTemplate] = []
  let prefix = name + "@"
  for key, tpl in self.entries {
    if key.starts_with(prefix) {
      result.push(tpl)
    }
  }
  result
}

///|
pub fn PromptRegistry::remove(
  self : PromptRegistry,
  name : String,
  version : String,
) -> Unit {
  self.entries.remove(name + "@" + version)
}

///|
pub fn PromptRegistry::count(self : PromptRegistry) -> Int {
  self.entries.length()
}
