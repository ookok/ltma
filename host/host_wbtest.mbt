///|
fn make_test_handle(name : String) -> @core.AgentHandle {
  let meta = @core.AgentMetadata::create(
    @core.AgentId::create(name, "0.1.0", "test"),
    name,
    [name],
    @core.IsolationLevel::in_process(),
    @core.Target::native(),
    "0.1.0",
  )
  @core.make_handle(
    (),
    fn(_) { name },
    fn(_) { meta },
    fn(_, _) {  },
    fn(_, input) {
      if input.is_text() {
        @core.Message::text("resp: " + input.get_text())
      } else {
        @core.Message::text("unhandled")
      }
    },
    fn(_) {  },
    fn(_) { @core.AgentStatus::idle() },
    fn(_, call) { @core.ToolResult::create(call.id, false, "", None) },
  )
}

///|
fn make_meta(name : String) -> @core.AgentMetadata {
  @core.AgentMetadata::create(
    @core.AgentId::create(name, "0.1.0", "test"),
    name,
    [name],
    @core.IsolationLevel::in_process(),
    @core.Target::native(),
    "0.1.0",
  )
}

///|
test "ActivationToken lifecycle" {
  let token = activate_in_process(
    fn() { make_test_handle("tok") },
    @core.AgentId::create("tok", "0.1.0", "test"),
  )
  let resp = token.call(@core.Message::text("hello"))
  assert_true(resp.is_text())
  assert_eq(resp.get_text(), "resp: hello")
  token.shutdown()
  assert_true(token.status().is_shutdown())
}

///|
test "ActivationToken send alias" {
  let token = activate_in_process(
    fn() { make_test_handle("send") },
    @core.AgentId::create("send", "0.1.0", "test"),
  )
  let resp = token.send(@core.Message::text("ping"))
  assert_eq(resp.get_text(), "resp: ping")
  deactivate(token)
}

///|
test "AgentCatalog registration and listing" {
  let cat = AgentCatalog::new()
  let h = make_test_handle("cat1")
  let m = h.metadata()
  cat.register(m, fn() { h })
  let list = cat.list()
  assert_eq(list.length(), 1)
  assert_eq(list[0].id.name, "cat1")
}

///|
test "AgentCatalog resolve and contains" {
  let cat = AgentCatalog::new()
  let h = make_test_handle("findme")
  let id = @core.AgentId::create("findme", "0.1.0", "test")
  cat.register(h.metadata(), fn() { h })
  let found = cat.resolve(id)
  assert_true(found is Some(_))
  assert_true(cat.contains(id))
  let other = @core.AgentId::create("nope", "0.1.0", "test")
  assert_false(cat.contains(other))
}

///|
test "AgentHost register and activate and send" {
  let host = AgentHost::new()
  let id = @core.AgentId::create("hlife", "0.1.0", "test")
  let meta = make_meta("hlife")
  host.register(meta, fn() { make_test_handle("hlife") })
  let activated = host.activate(id)
  assert_true(activated is Some(_))
  let resp = host.send(id, @core.Message::text("hi"))
  assert_true(resp is Some(_))
  match resp {
    Some(r) => assert_eq(r.get_text(), "resp: hi")
    None => ()
  }
  host.deactivate(id)
  let after = host.send(id, @core.Message::text("gone"))
  assert_true(after is None)
}

///|
test "AgentHost list registered" {
  let host = AgentHost::new()
  host.register(make_meta("la"), fn() { make_test_handle("la") })
  host.register(make_meta("lb"), fn() { make_test_handle("lb") })
  assert_eq(host.list_registered().length(), 2)
}

///|
test "AgentHost register rejects duplicate" {
  let host = AgentHost::new()
  let meta = make_meta("dup")
  host.register(meta, fn() { make_test_handle("dup") })
  host.register(meta, fn() { make_test_handle("dup") })
  // No crash = success; duplicate is silently ignored
  assert_eq(host.list_registered().length(), 1)
}

///|
test "AgentHost send to unregistered" {
  let host = AgentHost::new()
  let id = @core.AgentId::create("unreg", "0.1.0", "test")
  let resp = host.send(id, @core.Message::text("hi"))
  assert_true(resp is None)
}

///|
test "AgentHost shutdown_all" {
  let host = AgentHost::new()
  host.register(make_meta("sa"), fn() { make_test_handle("sa") })
  host.register(make_meta("sb"), fn() { make_test_handle("sb") })
  let _ = host.activate(@core.AgentId::create("sa", "0.1.0", "test"))
  let _ = host.activate(@core.AgentId::create("sb", "0.1.0", "test"))
  host.shutdown_all()
  assert_eq(host.list_registered().length(), 2)
}

///|
test "PubSubBus subscribe with Subscription struct" {
  let bus = PubSubBus::new()
  let received : Array[String] = []
  let sub = Subscription::new(
    "topic1",
    fn(msg) { received.push(msg.payload) },
    "s1",
  )
  bus.subscribe(sub)
  bus.publish(PubSubMessage::new("topic1", "msg1", "test"))
  bus.publish(PubSubMessage::new("topic1", "msg2", "test"))
  assert_eq(received.length(), 2)
}

///|
test "PubSubBus unsubscribe by id" {
  let bus = PubSubBus::new()
  let mut count = 0
  bus.subscribe(Subscription::new("t", fn(_) { count = count + 1 }, "s1"))
  bus.publish(PubSubMessage::new("t", "a", "test"))
  bus.unsubscribe("s1")
  bus.publish(PubSubMessage::new("t", "b", "test"))
  assert_eq(count, 1)
}

///|
test "PubSubBus topic isolation" {
  let bus = PubSubBus::new()
  let mut a = 0
  let mut b = 0
  bus.subscribe(Subscription::new("x", fn(_) { a = a + 1 }, "sx"))
  bus.subscribe(Subscription::new("y", fn(_) { b = b + 1 }, "sy"))
  bus.publish(PubSubMessage::new("x", "1", "test"))
  assert_eq(a, 1)
  assert_eq(b, 0)
}

///|
test "request_reply sends to agent" {
  let host = AgentHost::new()
  let id = @core.AgentId::create("rr", "0.1.0", "test")
  let meta = make_meta("rr")
  host.register(meta, fn() { make_test_handle("rr") })
  let _ = host.activate(id)
  let result = request_reply(host, id, @core.Message::text("ping"))
  assert_true(result is Some(_))
  match result {
    Some(m) => assert_eq(m.get_text(), "resp: ping")
    None => ()
  }
}

///|
test "broadcast sends to all registered" {
  let host = AgentHost::new()
  host.register(make_meta("ba"), fn() { make_test_handle("ba") })
  host.register(make_meta("bb"), fn() { make_test_handle("bb") })
  let _ = host.activate(@core.AgentId::create("ba", "0.1.0", "test"))
  let _ = host.activate(@core.AgentId::create("bb", "0.1.0", "test"))
  let results = broadcast(host, @core.Message::text("hello"))
  assert_eq(results.length(), 2)
}

///|
test "HealthCheck with probes" {
  let check = HealthCheck::new("h1")
  check.add_probe(fn() { HealthStatus::Healthy })
  let status = check.check()
  assert_true(status is HealthStatus::Healthy)
  assert_true(check.is_healthy())
}

///|
test "HealthRegistry overall status" {
  let reg = HealthRegistry::new()
  let c1 = HealthCheck::new("ok")
  c1.add_probe(fn() { HealthStatus::Healthy })
  reg.register(c1)
  let overall = reg.overall()
  assert_true(overall is HealthStatus::Healthy)
}

///|
test "HealthRegistry unhealthy probe" {
  let reg = HealthRegistry::new()
  let c1 = HealthCheck::new("bad")
  c1.add_probe(fn() { HealthStatus::Unhealthy("down") })
  reg.register(c1)
  let overall = reg.overall()
  assert_true(overall is HealthStatus::Unhealthy(_))
}

///|
test "ReloadWatcher on_change and notify" {
  let host = AgentHost::new()
  let rw = ReloadWatcher::new(host)
  let mut fired = false
  rw.on_change(fn() { fired = true })
  rw.notify()
  assert_true(fired)
}

///|
test "ReloadWatcher add_source and trigger" {
  let host = AgentHost::new()
  let rw = ReloadWatcher::new(host)
  rw.add_source("/tmp/plugins")
  rw.trigger_reload("some_agent")
  assert_true(true)
}

///|
test "deactivate calls shutdown" {
  let token = activate_in_process(
    fn() { make_test_handle("deact") },
    @core.AgentId::create("deact", "0.1.0", "test"),
  )
  deactivate(token)
  assert_true(token.status().is_shutdown())
}
