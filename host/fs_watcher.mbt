///|
/// File system watcher via C FFI — poll-based cross-platform directory monitoring.

///|
#borrow(path)
extern "c" fn _fs_list_dir(path : Bytes) -> Bytes = "fs_list_dir"

///|
#borrow(path)
extern "c" fn _fs_get_mtime(path : Bytes) -> Int64 = "fs_get_mtime"

///|
/// List files in a directory. Returns filenames (not full paths).
pub fn list_dir(path : String) -> Array[String] {
  let raw = _fs_list_dir(@utf8.encode(path))
  if raw.length() == 0 {
    return []
  }
  let text = @utf8.decode_lossy(raw)
  let result : Array[String] = []
  for part in text.split("\n") {
    let name = part.to_owned()
    if name.length() > 0 {
      result.push(name)
    }
  }
  result
}

///|
/// Get file modification time in milliseconds since epoch, or -1 if error.
pub fn get_mtime(path : String) -> Int64 {
  _fs_get_mtime(@utf8.encode(path))
}

///|
/// FsWatcher — poll-based file system change monitor.
///
/// Stores a flat list of watched files with their last-known modification times.
/// On each `poll()`, re-checks all files and returns paths that changed.
pub struct FsWatcher {
  mut files : Array[(String, Int64)]
}

///|
pub fn FsWatcher::new() -> FsWatcher {
  { files: [] }
}

///|
/// Add a single file to the watch list.
pub fn FsWatcher::add_file(self : FsWatcher, path : String) -> Unit {
  let mtime = get_mtime(path)
  self.files.push((path, mtime))
}

///|
/// Add all files in a directory to the watch list.
pub fn FsWatcher::add_dir(self : FsWatcher, dir_path : String) -> Unit {
  let names = list_dir(dir_path)
  for name in names {
    let full = dir_path + "/" + name
    let mtime = get_mtime(full)
    self.files.push((full, mtime))
  }
}

///|
/// Poll for changes. Returns paths that have been modified since last poll.
pub fn FsWatcher::poll(self : FsWatcher) -> Array[String] {
  let changed : Array[String] = []
  for i = 0; i < self.files.length(); i = i + 1 {
    let (path, old_mtime) = self.files[i]
    let new_mtime = get_mtime(path)
    if new_mtime >= 0L && new_mtime != old_mtime {
      changed.push(path)
      self.files[i] = (path, new_mtime)
    }
  }
  changed
}

///|
/// Clear all watched files.
pub fn FsWatcher::clear(self : FsWatcher) -> Unit {
  self.files = []
}

///|
/// Number of files being watched.
pub fn FsWatcher::len(self : FsWatcher) -> Int {
  self.files.length()
}
