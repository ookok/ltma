///|
/// Knowledge Agent — LLM + Knowledge Graph for semantic memory.

///|
/// Create an AgentHandle with integrated Knowledge Graph.
pub fn create_knowledge_agent_handle(
  provider : @llm.LLMProviderHandle,
  registry : @tool.ToolRegistry,
  kg : @memory.KnowledgeGraph,
  ki : @memory.KeywordIndex,
) -> @core.AgentHandle {
  let mut messages : Array[@llm.ChatMessage] = []
  messages.push(
    @llm.ChatMessage::new(
      @llm.ChatRole::system(),
      "You are an AI assistant with long-term memory. You can store and recall facts.",
    ),
  )

  @core.make_handle(
    (),
    fn(_) { "knowledge-agent" },
    fn(_) {
      @core.AgentMetadata::create(
        @core.AgentId::create("knowledge", "0.1.0", "livingtree/ltma"),
        "Agent with knowledge graph memory",
        ["knowledge", "memory", "semantic", "facts"],
        @core.IsolationLevel::in_process(),
        @core.Target::native(),
        "0.1.0",
      )
    },
    fn(_, _ctx) { messages = [] },
    fn(_, input) -> @core.Message {
      if input.is_text() {
        let user_text = input.get_text()
        let context = build_knowledge_context(kg, ki, user_text)
        let full_prompt = if context != "" {
          "Context: \{context}|\{user_text}"
        } else {
          user_text
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
    fn(_) { messages = [] },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, call) -> @core.ToolResult {
      let result = registry.execute(call.name, call.arguments)
      @core.ToolResult::create(
        call.id,
        result is Some(_),
        result.unwrap_or(""),
        None,
      )
    },
  )
}

///|
fn build_knowledge_context(
  kg : @memory.KnowledgeGraph,
  ki : @memory.KeywordIndex,
  query : String,
) -> String {
  let parts : Array[String] = []

  let entities = kg.search_entities(query)
  for e in entities {
    parts.push("- \{e.name} (\{e.entity_type}): \{e.metadata}")
    let rels = kg.query_relations(e.id)
    for r in rels {
      match kg.get_entity(r.object) {
        Some(obj) => parts.push("  ~ related to \{obj.name} via \{r.predicate}")
        None => ()
      }
    }
  }

  let docs = ki.search(query)
  for i = 0; i < docs.length(); i = i + 1 {
    let entry = docs[i]
    let doc = entry.2
    parts.push("- Doc: \{doc.title} — \{doc.content}")
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
