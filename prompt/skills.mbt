///|
/// Skill system — load and manage domain knowledge for agents.

///|
/// A skill is a named block of knowledge that can be injected into prompts.
pub struct Skill {
  name : String
  description : String
  content : String
}

///|
pub fn Skill::new(name : String, description : String, content : String) -> Skill {
  { name, description, content }
}

///|
/// Skill registry — manages loaded skills.
pub struct SkillRegistry {
  skills : Map[String, Skill]
}

///|
pub fn SkillRegistry::new() -> SkillRegistry {
  { skills: Map([]) }
}

///|
pub fn SkillRegistry::register(self : SkillRegistry, skill : Skill) -> Unit {
  self.skills[skill.name] = skill
}

///|
pub fn SkillRegistry::load(
  self : SkillRegistry,
  name : String,
) -> Skill? {
  self.skills.get(name)
}

///|
pub fn SkillRegistry::list(self : SkillRegistry) -> Array[String] {
  let result : Array[String] = []
  for name, _ in self.skills {
    result.push(name)
  }
  result
}

///|
/// Get all skill contents as a formatted string for prompt injection.
pub fn SkillRegistry::to_context(self : SkillRegistry) -> String {
  let mut result = ""
  for _, skill in self.skills {
    result = result + "=== " + skill.name + " ===\n"
    result = result + skill.description + "\n"
    result = result + skill.content + "\n\n"
  }
  result
}
