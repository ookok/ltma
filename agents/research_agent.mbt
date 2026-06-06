///|
/// ResearchAgent — multi-source research synthesis with citations.
fn build_research_context(
  kg : @memory.KnowledgeGraph,
  ki : @memory.KeywordIndex,
  query : String,
) -> String {
  let parts : Array[String] = []
  let mut source_id = 1

  let entities = kg.search_entities(query)
  for e in entities {
    parts.push(
      "[Source \{source_id}] \{e.name} (\{e.entity_type}): \{e.metadata}",
    )
    source_id = source_id + 1
    let rels = kg.query_relations(e.id)
    for r in rels {
      match kg.get_entity(r.object) {
        Some(obj) =>
          parts.push("  ~ relation: \{e.name} --\{r.predicate}--> \{obj.name}")
        None => ()
      }
    }
  }

  let docs = ki.search(query)
  for i = 0; i < docs.length(); i = i + 1 {
    let entry = docs[i]
    let doc = entry.2
    parts.push("[Source \{source_id}] \{doc.title}: \{doc.content}")
    source_id = source_id + 1
  }

  let mut result = ""
  for j = 0; j < parts.length(); j = j + 1 {
    if j > 0 {
      result = result + "\n"
    }
    result = result + parts[j]
  }
  result
}

///|
pub fn create_research_agent_handle(
  provider : @llm.LLMProviderHandle,
  registry : @tool.ToolRegistry,
  kg : @memory.KnowledgeGraph,
  ki : @memory.KeywordIndex,
) -> @core.AgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  messages.push(
    @llm.ChatMessage::new(
      @llm.ChatRole::system(),
      "You are a research assistant. Synthesize information from multiple sources into clear, well-organized answers. Cite sources by number when possible. If sources are insufficient, state what is known and identify gaps.",
    ),
  )

  @core.make_handle(
    (),
    fn(_) -> String { "research-agent" },
    fn(_) -> @core.AgentMetadata {
      @core.AgentMetadata::create(
        @core.AgentId::create("research", "0.1.0", "livingtree/ltma"),
        "Multi-source research agent with KG/KI synthesis",
        ["research", "knowledge", "synthesis", "search", "facts"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx : @core.AgentContext) -> Unit { messages = [] },
    fn(_, input : @core.Message) -> @core.Message {
      if input.is_text() {
        let user_text = input.get_text()
        let context = build_research_context(kg, ki, user_text)
        let full_prompt = if context != "" {
          "Research query: \{user_text}|\n\nAvailable sources:\n\{context}|\n\nProvide a well-structured answer citing sources."
        } else {
          "Research query: \{user_text}|\n\nNo specific sources found. Answer based on general knowledge and identify knowledge gaps."
        }
        messages.push(@llm.ChatMessage::new(@llm.ChatRole::user(), full_prompt))
        let resp = provider.chat(messages, None)
        messages.push(
          @llm.ChatMessage::new(@llm.ChatRole::assistant(), resp.content),
        )
        @core.Message::text(resp.content)
      } else {
        @core.Message::text("unsupported")
      }
    },
    fn(_) -> Unit { messages = [] },
    fn(_) -> @core.AgentStatus { @core.AgentStatus::idle() },
    fn(_, call : @core.ToolCall) -> @core.ToolResult {
      let result = registry.execute(call.name, call.arguments)
      let success = result is Some(_)
      let output = result.unwrap_or("")
      @core.ToolResult::create(call.id, success, output, None)
    },
  )
}
