///|
/// StreamingBuffer — signal-backed text accumulator.
pub struct StreamingBuffer {
  full : @signals.Signal[String]
  revealed : @signals.Signal[Int]
}

///|
pub fn StreamingBuffer::new() -> StreamingBuffer {
  { full: @signals.Signal::new(""), revealed: @signals.Signal::new(0) }
}

///|
pub fn StreamingBuffer::append(self : StreamingBuffer, chunk : String) -> Unit {
  let current = self.full.get()
  self.full.set(current + chunk)
}

///|
pub fn StreamingBuffer::set_text(self : StreamingBuffer, text : String) -> Unit {
  self.full.set(text)
  self.revealed.set(text.length())
}

///|
pub fn StreamingBuffer::reveal_all(self : StreamingBuffer) -> Unit {
  self.revealed.set(self.full.get().length())
}

///|
pub fn StreamingBuffer::reveal_one_more(self : StreamingBuffer) -> Unit {
  self.reveal_n(1)
}

///|
pub fn StreamingBuffer::reveal_n(self : StreamingBuffer, n : Int) -> Unit {
  let r = self.revealed.get()
  let max = self.full.get().length()
  let next = r + n
  if next >= max {
    self.revealed.set(max)
  } else {
    self.revealed.set(next)
  }
}

///|
pub fn StreamingBuffer::display(self : StreamingBuffer) -> String {
  let end = self.revealed.get()
  let s = self.full.get()
  if end >= s.length() {
    s
  } else {
    s[:end].to_owned()
  }
}

///|
pub fn StreamingBuffer::is_complete(self : StreamingBuffer) -> Bool {
  self.revealed.get() >= self.full.get().length()
}

///|
pub fn StreamingBuffer::full_text(self : StreamingBuffer) -> String {
  self.full.get()
}

///|
pub fn StreamingBuffer::clear(self : StreamingBuffer) -> Unit {
  self.full.set("")
  self.revealed.set(0)
}
