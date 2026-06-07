///|
/// Streaming — chunked/streaming response support for LLM and agent calls.

///|
/// StreamChunk — a single chunk in a streaming response.
pub struct StreamChunk {
  text : String
  index : Int
  is_last : Bool
}

///|
pub fn StreamChunk::new(
  text : String,
  index : Int,
  is_last : Bool,
) -> StreamChunk {
  { text, index, is_last }
}

///|
/// StreamCallback — invoked for each chunk during streaming.
pub type StreamCallback = (StreamChunk) -> Unit

///|
/// StreamHandle — controls an active streaming session.
pub struct StreamHandle {
  mut cancelled : Bool
  mut on_chunk : StreamCallback
  on_complete : () -> Unit
  on_error : (String) -> Unit
}

///|
pub fn StreamHandle::new(
  on_chunk : StreamCallback,
  on_complete : () -> Unit,
  on_error : (String) -> Unit,
) -> StreamHandle {
  { cancelled: false, on_chunk, on_complete, on_error }
}

///|
pub fn StreamHandle::cancel(self : StreamHandle) -> Unit {
  self.cancelled = true
}

///|
pub fn StreamHandle::is_cancelled(self : StreamHandle) -> Bool {
  self.cancelled
}

///|
pub fn StreamHandle::send(self : StreamHandle, chunk : StreamChunk) -> Unit {
  if !self.cancelled {
    (self.on_chunk)(chunk)
    if chunk.is_last {
      (self.on_complete)()
    }
  }
}

///|
pub fn StreamHandle::error(self : StreamHandle, msg : String) -> Unit {
  if !self.cancelled {
    (self.on_error)(msg)
  }
}

///|
/// StreamResult — either a full response or a stream handle for chunked delivery.
pub enum StreamResult {
  Full(Message)
  Stream(StreamHandle)
}

///|
/// Collect stream chunks into a single string (for testing/buffering).
pub fn collect_stream(handle : StreamHandle) -> String {
  let mut buffer = ""
  let original = handle.on_chunk
  handle.on_chunk = fn(chunk) {
    buffer = buffer + chunk.text
    original(chunk)
  }
  buffer
}
