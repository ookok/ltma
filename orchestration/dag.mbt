///|
/// DAG-based agent composition — directed acyclic graph execution flow.

///|
/// DagNode — a single step in a DAG pipeline.
pub struct DagNode {
  name : String
  agent_name : String
  depends_on : Array[String]
}

///|
pub fn DagNode::new(
  name : String,
  agent_name : String,
  depends_on : Array[String],
) -> DagNode {
  { name, agent_name, depends_on }
}

///|
/// DagPipeline — a directed acyclic graph of agent execution steps.
pub struct DagPipeline {
  nodes : Map[String, DagNode]
  mut entry_points : Array[String]
}

///|
pub fn DagPipeline::new() -> DagPipeline {
  { nodes: Map([]), entry_points: [] }
}

///|
pub fn DagPipeline::add_node(self : DagPipeline, node : DagNode) -> Unit {
  let key = node.name
  self.nodes[key] = node
  // Recompute entry points
  let entries : Array[String] = []
  let has_dependents : Map[String, Bool] = Map([])
  for _, n in self.nodes {
    for dep in n.depends_on {
      has_dependents[dep] = true
    }
  }
  for name, _ in self.nodes {
    if !has_dependents.contains(name) {
      entries.push(name)
    }
  }
  self.entry_points = entries
}

///|
pub fn DagPipeline::get_node(self : DagPipeline, name : String) -> DagNode? {
  self.nodes.get(name)
}

///|
pub fn DagPipeline::topological_order(self : DagPipeline) -> Array[String] {
  let visited : Map[String, Bool] = Map([])
  let result : Array[String] = []
  for entry in self.entry_points {
    dfs_sort(self.nodes, entry, visited, result)
  }
  result
}

///|
fn dfs_sort(
  nodes : Map[String, DagNode],
  current : String,
  visited : Map[String, Bool],
  result : Array[String],
) -> Unit {
  if visited.contains(current) {
    return
  }
  visited[current] = true
  for _, node in nodes {
    for dep in node.depends_on {
      if dep == current {
        dfs_sort(nodes, node.name, visited, result)
      }
    }
  }
  result.push(current)
}

///|
/// DagExecutor — runs a DAG pipeline against an AgentHost.
pub struct DagExecutor {
  host : @host.AgentHost
}

///|
pub fn DagExecutor::new(host : @host.AgentHost) -> DagExecutor {
  { host, }
}

///|
pub fn DagExecutor::execute(
  self : DagExecutor,
  pipeline : DagPipeline,
  input : String,
) -> Map[String, String] {
  let results : Map[String, String] = Map([])
  let order = pipeline.topological_order()
  for node_name in order {
    match pipeline.get_node(node_name) {
      Some(node) => {
        let dep_input = if node.depends_on.length() == 0 {
          input
        } else {
          let parts : Array[String] = []
          for dep in node.depends_on {
            match results.get(dep) {
              Some(val) => parts.push(val)
              None => ()
            }
          }
          parts.join("\n")
        }
        let id = @core.AgentId::create(
          node.agent_name,
          "0.1.0",
          "livingtree/ltma",
        )
        match self.host.activate(id) {
          Some(token) => {
            let resp = token.call(@core.Message::text(dep_input))
            token.shutdown()
            let text = if resp.is_text() { resp.get_text() } else { "" }
            results[node_name] = text
          }
          None =>
            results[node_name] = "error: agent not found: \{node.agent_name}"
        }
      }
      None => ()
    }
  }
  results
}
