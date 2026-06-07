///|
/// Agent communication patterns — request/reply, pub/sub, broadcast.

///|
/// RequestReply — synchronous request/response between agents.
pub fn request_reply(
  host : AgentHost,
  target_id : @core.AgentId,
  request : @core.Message,
) -> @core.Message? {
  host.send(target_id, request)
}

///|
/// PubSubMessage — a message for publish/subscribe pattern.
pub struct PubSubMessage {
  topic : String
  payload : String
  sender : String
}

///|
pub fn PubSubMessage::new(
  topic : String,
  payload : String,
  sender : String,
) -> PubSubMessage {
  { topic, payload, sender }
}

///|
/// Subscription — a topic subscription with handler.
pub struct Subscription {
  topic : String
  handler : (PubSubMessage) -> Unit
  subscription_id : String
}

///|
pub fn Subscription::new(
  topic : String,
  handler : (PubSubMessage) -> Unit,
  subscription_id : String,
) -> Subscription {
  { topic, handler, subscription_id }
}

///|
/// PubSubBus — topic-based publish/subscribe message bus.
pub struct PubSubBus {
  subscriptions : Map[String, Array[Subscription]]
}

///|
pub fn PubSubBus::new() -> PubSubBus {
  { subscriptions: Map([]) }
}

///|
pub fn PubSubBus::subscribe(self : PubSubBus, sub : Subscription) -> Unit {
  match self.subscriptions.get(sub.topic) {
    Some(subs) => subs.push(sub)
    None => self.subscriptions[sub.topic] = [sub]
  }
}

///|
pub fn PubSubBus::publish(self : PubSubBus, msg : PubSubMessage) -> Unit {
  match self.subscriptions.get(msg.topic) {
    Some(subs) =>
      for sub in subs {
        (sub.handler)(msg)
      }
    None => ()
  }
}

///|
pub fn PubSubBus::unsubscribe(
  self : PubSubBus,
  subscription_id : String,
) -> Unit {
  for topic, subs in self.subscriptions {
    let mut i = 0
    while i < subs.length() {
      if subs[i].subscription_id == subscription_id {
        let _ = subs.remove(i)
      } else {
        i = i + 1
      }
    }
  }
}

///|
/// Broadcast — send a message to all registered agents.
pub fn broadcast(host : AgentHost, msg : @core.Message) -> Array[@core.Message] {
  let results : Array[@core.Message] = []
  let agents = host.list_registered()
  for meta in agents {
    match host.send(meta.id, msg) {
      Some(resp) => results.push(resp)
      None => ()
    }
  }
  results
}
