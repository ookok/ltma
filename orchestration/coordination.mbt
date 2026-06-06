///|
/// Multi-agent coordination patterns — debate, voting, consensus.

///|
/// Run a debate between two agents on a topic.
pub fn debate(
  host : @host.AgentHost,
  topic : String,
  agent_a : String,
  agent_b : String,
  rounds : Int,
) -> Array[(String, String)] {
  let transcript : Array[(String, String)] = []
  let id_a = @core.AgentId::create(agent_a, "0.1.0", "livingtree/ltma")
  let id_b = @core.AgentId::create(agent_b, "0.1.0", "livingtree/ltma")
  let mut prompt = topic
  for i = 0; i < rounds; i = i + 1 {
    match host.activate(id_a) {
      Some(a) => {
        let r = a.call(@core.Message::text(prompt))
        a.shutdown()
        let text = if r.is_text() { r.get_text() } else { "" }
        transcript.push((agent_a, text))
        prompt = agent_a + " said: " + text + ". " + agent_b + ", please respond."
      }
      None => ()
    }
    match host.activate(id_b) {
      Some(b) => {
        let r = b.call(@core.Message::text(prompt))
        b.shutdown()
        let text = if r.is_text() { r.get_text() } else { "" }
        transcript.push((agent_b, text))
        prompt = agent_b + " said: " + text + ". " + agent_a + ", please respond."
      }
      None => ()
    }
  }
  transcript
}

///|
/// Vote: ask multiple agents and return majority choice.
pub fn vote(
  host : @host.AgentHost,
  question : String,
  choices : Array[String],
) -> Map[String, Int] {
  let counts : Map[String, Int] = Map([])
  let agents = host.list_registered()
  for a in agents {
    let id = a.id
    match host.activate(id) {
      Some(adapter) => {
        let prompt = question + "\nChoices: " + format_choices(choices)
        let r = adapter.call(@core.Message::text(prompt))
        adapter.shutdown()
        if r.is_text() {
          let answer = r.get_text().trim().to_owned()
          let current = counts.get(answer).unwrap_or(0)
          counts[answer] = current + 1
        }
      }
      None => ()
    }
  }
  counts
}

///|
fn format_choices(choices : Array[String]) -> String {
  let mut result = ""
  for i = 0; i < choices.length(); i = i + 1 {
    if i > 0 { result = result + ", " }
    result = result + (i + 1).to_string() + ". " + choices[i]
  }
  result
}
