///|
/// Agent Router — intent-based routing to the most capable agent.

///|
/// RoutingIntent — what the caller wants to accomplish.
pub struct RoutingIntent {
  action : String
  context : Map[String, String]
}

///|
pub fn RoutingIntent::new(action : String) -> RoutingIntent {
  { action, context: Map([]) }
}

///|
pub fn RoutingIntent::set(
  self : RoutingIntent,
  key : String,
  value : String,
) -> Unit {
  self.context[key] = value
}

///|
pub fn RoutingIntent::get(self : RoutingIntent, key : String) -> String? {
  self.context.get(key)
}

///|
/// RoutingMatch — result of routing an intent.
pub struct RoutingMatch {
  agent_id : @core.AgentId
  confidence : Double
}

///|
pub fn RoutingMatch::new(
  agent_id : @core.AgentId,
  confidence : Double,
) -> RoutingMatch {
  { agent_id, confidence }
}

///|
/// AgentRouter — resolves intents to registered agents.
pub struct AgentRouter {
  catalog : AgentCatalog
}

///|
pub fn AgentRouter::new(catalog : AgentCatalog) -> AgentRouter {
  { catalog, }
}

///|
pub fn AgentRouter::route(
  self : AgentRouter,
  intent : RoutingIntent,
) -> RoutingMatch? {
  let candidates = self.catalog.list()
  let action = intent.action
  let mut best : RoutingMatch? = None
  let mut best_score = 0.0
  for meta in candidates {
    for cap in meta.capabilities {
      if cap == action {
        let score = 1.0
        if score > best_score {
          best_score = score
          best = Some(RoutingMatch::new(meta.id, score))
        }
      }
    }
  }
  best
}

///|
pub fn AgentRouter::route_all(
  self : AgentRouter,
  intent : RoutingIntent,
) -> Array[RoutingMatch] {
  let result : Array[RoutingMatch] = []
  let candidates = self.catalog.list()
  let action = intent.action
  for meta in candidates {
    for cap in meta.capabilities {
      if cap == action {
        result.push(RoutingMatch::new(meta.id, 1.0))
      }
    }
  }
  result
}
