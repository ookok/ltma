///|
/// AgentHost — the central orchestrator with full subsystem integration.

///|
/// AgentHostConfig — configuration for the AgentHost.
pub struct AgentHostConfig {
  policy : @security.SecurityPolicy
  bulkhead_config : @core.BulkheadConfig
  timeout_policy : @core.TimeoutPolicy
  audit_max_entries : Int
}

///|
pub fn AgentHostConfig::default() -> AgentHostConfig {
  {
    policy: @security.SecurityPolicy::default(),
    bulkhead_config: @core.BulkheadConfig::default(),
    timeout_policy: @core.TimeoutPolicy::default(),
    audit_max_entries: 1000,
  }
}

///|
/// AgentHost — the central orchestrator with full subsystem integration.
pub struct AgentHost {
  catalog : AgentCatalog
  bus : EventBus
  active : Map[String, ActivationToken]
  a2a : @protocol.A2ARouter
  metrics : @telemetry.MetricsRegistry
  tracer : @telemetry.Tracer
  policy_engine : @security.PolicyEngine
  audit_log : @security.AuditLog
  bulkheads : @core.BulkheadRegistry
  timeout_tracker : @core.TimeoutTracker
  health_registry : HealthRegistry
  config : AgentHostConfig
}

///|
pub fn AgentHost::new() -> AgentHost {
  let config = AgentHostConfig::default()
  {
    catalog: AgentCatalog::new(),
    bus: EventBus::new(),
    active: Map([]),
    a2a: @protocol.A2ARouter::new(),
    metrics: @telemetry.MetricsRegistry::new(),
    tracer: @telemetry.Tracer::new("ltma"),
    policy_engine: @security.PolicyEngine::new(config.policy),
    audit_log: @security.AuditLog::new(config.audit_max_entries),
    bulkheads: @core.BulkheadRegistry::new(),
    timeout_tracker: @core.TimeoutTracker::new(),
    health_registry: HealthRegistry::new(),
    config,
  }
}

///|
pub fn AgentHost::new_with_config(config : AgentHostConfig) -> AgentHost {
  {
    catalog: AgentCatalog::new(),
    bus: EventBus::new(),
    active: Map([]),
    a2a: @protocol.A2ARouter::new(),
    metrics: @telemetry.MetricsRegistry::new(),
    tracer: @telemetry.Tracer::new("ltma"),
    policy_engine: @security.PolicyEngine::new(config.policy),
    audit_log: @security.AuditLog::new(config.audit_max_entries),
    bulkheads: @core.BulkheadRegistry::new(),
    timeout_tracker: @core.TimeoutTracker::new(),
    health_registry: HealthRegistry::new(),
    config,
  }
}

///|
pub fn AgentHost::register(
  self : AgentHost,
  metadata : @core.AgentMetadata,
  factory : () -> @core.AgentHandle,
) -> Unit {
  let agent_name = metadata.id.name
  let policy_check = self.policy_engine.check_agent(agent_name)
  if policy_check is @security.PolicyAction::Deny {
    self.audit_log.log(
      @security.AuditEvent::permission_check(agent_name, "register", false),
    )
    return
  }
  self.catalog.register(metadata, factory)
  self.bus.publish(HostEvent::AgentRegistered(metadata.id))
  self.audit_log.log(@security.AuditEvent::agent_created(agent_name))
  let _ = self.metrics.counter("agents.registered").inc(1L)
}

///|
pub fn AgentHost::activate(
  self : AgentHost,
  agent_id : @core.AgentId,
) -> ActivationToken? {
  let agent_name = agent_id.name
  let bulkhead = self.bulkheads.get_or_create(
    "agent." + agent_name,
    self.config.bulkhead_config,
  )
  if !bulkhead.try_acquire() {
    self.audit_log.log(
      @security.AuditEvent::permission_check(agent_name, "activate", false),
    )
    return None
  }

  let reg = self.catalog.resolve(agent_id)
  if reg is None {
    bulkhead.release()
    return None
  }
  let r = reg.unwrap()
  let token = activate_in_process(r.factory, agent_id)
  let key = agent_id.to_string()
  self.active[key] = token
  self.bus.publish(HostEvent::AgentActivated(agent_id))
  self.audit_log.log(@security.AuditEvent::agent_created(agent_name))
  let _ = self.metrics.counter("agents.active").inc(1L)
  Some(token)
}

///|
pub fn AgentHost::deactivate(
  self : AgentHost,
  agent_id : @core.AgentId,
) -> Unit {
  let key = agent_id.to_string()
  match self.active.get(key) {
    Some(token) => {
      let agent_name = agent_id.name
      token.shutdown()
      self.active.remove(key)
      self.bus.publish(HostEvent::AgentDeactivated(agent_id))
      self.audit_log.log(@security.AuditEvent::agent_destroyed(agent_name))
      let _ = self.metrics.counter("agents.active").inc(-1L)
      let bulkhead = self.bulkheads.get_or_create(
        "agent." + agent_name,
        self.config.bulkhead_config,
      )
      bulkhead.release()
    }
    None => ()
  }
}

///|
pub fn AgentHost::send(
  self : AgentHost,
  agent_id : @core.AgentId,
  msg : @core.Message,
) -> @core.Message? {
  let agent_name = agent_id.name
  let msg_size = if msg.is_text() { msg.get_text().length() } else { 256 }
  let size_check = self.policy_engine.check_message_size(msg_size)
  if size_check is @security.PolicyAction::Deny {
    self.audit_log.log(
      @security.AuditEvent::permission_check(
        agent_name,
        "send:" + msg_size.to_string(),
        false,
      ),
    )
    return None
  }

  let key = agent_id.to_string()
  match self.active.get(key) {
    Some(token) => {
      self.bus.publish(HostEvent::AgentMessageSent(agent_id, msg))

      if msg.is_system_shutdown() || msg.is_system_status_request() {
        let resp = token.send(msg)
        self.bus.publish(HostEvent::AgentMessageReceived(agent_id, resp))
        Some(resp)
      } else {
        let span = self.tracer.start("agent." + agent_name)
        span.tag("msg_type", if msg.is_text() { "text" } else { "other" })
        let resp = token.send_with_trace(msg, span.trace_id, span.span_id)
        span.finish()
        self.bus.publish(HostEvent::AgentMessageReceived(agent_id, resp))
        self.audit_log.log(
          @security.AuditEvent::message_sent(
            agent_name,
            if msg.is_text() {
              msg.get_text()
            } else {
              "<binary>"
            },
          ),
        )
        let _ = self.metrics.counter("messages.sent").inc(1L)
        Some(resp)
      }
    }
    None => None
  }
}

///|
pub fn AgentHost::list_registered(
  self : AgentHost,
) -> Array[@core.AgentMetadata] {
  self.catalog.list()
}

///|
pub fn AgentHost::register_a2a(
  self : AgentHost,
  agent_name : String,
  handler : @protocol.A2AEventHandler,
) -> Unit {
  self.a2a.register(agent_name, handler)
}

///|
pub fn AgentHost::send_a2a(
  self : AgentHost,
  msg : @protocol.A2AMessage,
) -> @protocol.A2AMessage? {
  self.a2a.send(msg)
}

///|
pub fn AgentHost::a2a_broadcast(
  self : AgentHost,
  msg : @protocol.A2AMessage,
) -> Array[@protocol.A2AMessage] {
  self.a2a.broadcast(msg)
}

///|
pub fn AgentHost::metrics_registry(
  self : AgentHost,
) -> @telemetry.MetricsRegistry {
  self.metrics
}

///|
pub fn AgentHost::tracer(self : AgentHost) -> @telemetry.Tracer {
  self.tracer
}

///|
pub fn AgentHost::policy_engine(self : AgentHost) -> @security.PolicyEngine {
  self.policy_engine
}

///|
pub fn AgentHost::audit_log(self : AgentHost) -> @security.AuditLog {
  self.audit_log
}

///|
pub fn AgentHost::health_registry(self : AgentHost) -> HealthRegistry {
  self.health_registry
}

///|
pub fn AgentHost::bulkheads(self : AgentHost) -> @core.BulkheadRegistry {
  self.bulkheads
}

///|
pub fn AgentHost::timeout_tracker(self : AgentHost) -> @core.TimeoutTracker {
  self.timeout_tracker
}

///|
pub fn AgentHost::shutdown_all(self : AgentHost) -> Unit {
  let keys : Array[String] = []
  for k, _ in self.active {
    keys.push(k)
  }
  for key in keys {
    let agent_id = @core.AgentId::create(key, "0.1.0", "livingtree/ltma")
    self.deactivate(agent_id)
  }
}
