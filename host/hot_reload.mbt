///|
/// Hot reload — watch and reload agents without restart.

///|
/// ReloadEvent — describes what changed during a hot reload.
pub struct ReloadEvent {
  agent_id : String
  action : ReloadAction
}

///|
pub enum ReloadAction {
  Reloaded
  Failed
  Removed
}

///|
/// ReloadEvent::new — create a reload event.
pub fn ReloadEvent::new(
  agent_id : String,
  action : ReloadAction,
) -> ReloadEvent {
  { agent_id, action }
}

///|
/// ReloadWatcher — monitors and reloads agents.
pub struct ReloadWatcher {
  host : AgentHost
  sources : Array[String]
  watchers : Array[() -> Unit]
  fs_watcher : FsWatcher
}

///|
pub fn ReloadWatcher::new(host : AgentHost) -> ReloadWatcher {
  { host, sources: [], watchers: [], fs_watcher: FsWatcher::new() }
}

///|
pub fn ReloadWatcher::add_source(self : ReloadWatcher, path : String) -> Unit {
  self.sources.push(path)
  // Add to file watcher for change tracking
  self.fs_watcher.add_file(path)
}

///|
/// Poll file system for changes. Returns changed file paths.
/// Must be called periodically (e.g. from an async loop).
pub fn ReloadWatcher::watch(self : ReloadWatcher) -> Array[String] {
  let changed = self.fs_watcher.poll()
  if changed.length() > 0 {
    self.notify()
  }
  changed
}

///|
pub fn ReloadWatcher::trigger_reload(
  self : ReloadWatcher,
  agent_id : String,
) -> Unit {
  let id = @core.AgentId::create(agent_id, "0.1.0", "livingtree/ltma")
  self.host.deactivate(id)
  // Re-registration would happen here
  ()
}

///|
pub fn ReloadWatcher::on_change(
  self : ReloadWatcher,
  callback : () -> Unit,
) -> Unit {
  self.watchers.push(callback)
}

///|
pub fn ReloadWatcher::notify(self : ReloadWatcher) -> Unit {
  for cb in self.watchers {
    cb()
  }
}
