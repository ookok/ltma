///|
/// Knowledge Graph — entities, relationships, and document knowledge store.

///|
pub struct Entity {
  id : String
  name : String
  entity_type : String
  metadata : String
}

///|
pub fn Entity::new(
  id : String,
  name : String,
  entity_type : String,
  metadata : String,
) -> Entity {
  { id, name, entity_type, metadata }
}

///|
pub struct Relation {
  subject : String
  predicate : String
  object : String
}

///|
pub fn Relation::new(
  subject : String,
  predicate : String,
  object : String,
) -> Relation {
  { subject, predicate, object }
}

///|
pub struct KnowledgeGraph {
  entities : Map[String, Entity]
  relations : Array[Relation]
}

///|
pub fn KnowledgeGraph::new() -> KnowledgeGraph {
  { entities: Map([]), relations: [] }
}

///|
pub fn KnowledgeGraph::add_entity(
  self : KnowledgeGraph,
  entity : Entity,
) -> Unit {
  self.entities[entity.id] = entity
}

///|
pub fn KnowledgeGraph::get_entity(
  self : KnowledgeGraph,
  id : String,
) -> Entity? {
  self.entities.get(id)
}

///|
pub fn KnowledgeGraph::remove_entity(
  self : KnowledgeGraph,
  id : String,
) -> Unit {
  self.entities.remove(id)
}

///|
pub fn KnowledgeGraph::add_relation(
  self : KnowledgeGraph,
  rel : Relation,
) -> Unit {
  self.relations.push(rel)
}

///|
pub fn KnowledgeGraph::query_relations(
  self : KnowledgeGraph,
  subject : String,
) -> Array[Relation] {
  let result : Array[Relation] = []
  for r in self.relations {
    if r.subject == subject {
      result.push(r)
    }
  }
  result
}

///|
pub fn KnowledgeGraph::query_by_type(
  self : KnowledgeGraph,
  entity_type : String,
) -> Array[Entity] {
  let result : Array[Entity] = []
  for _, e in self.entities {
    if e.entity_type == entity_type {
      result.push(e)
    }
  }
  result
}

///|
pub fn KnowledgeGraph::search_entities(
  self : KnowledgeGraph,
  query : String,
) -> Array[Entity] {
  let q = query.to_lower()
  let result : Array[Entity] = []
  for _, e in self.entities {
    if e.name.to_lower().contains(q) || e.metadata.to_lower().contains(q) {
      result.push(e)
    }
  }
  result
}

///|
pub fn KnowledgeGraph::count(self : KnowledgeGraph) -> (Int, Int) {
  (self.entities.length(), self.relations.length())
}
