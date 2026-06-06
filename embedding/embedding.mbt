///|
/// ONNX Runtime-based embedding provider via C FFI.

///|
#owned(model_path, vocab_path)
extern "c" fn _embedding_init(model_path : Bytes, vocab_path : Bytes) -> Int64 = "embedding_init"

///|
#external(handle)
#owned(text)
extern "c" fn _embedding_get(handle : Int64, text : Bytes) -> Int = "embedding_get"

///|
#external(handle)
extern "c" fn _embedding_read(handle : Int64, index : Int) -> Double = "embedding_read"

///|
extern "c" fn _embedding_dim() -> Int = "embedding_dim"

///|
#external(handle)
extern "c" fn _embedding_free(handle : Int64) = "embedding_free"

///|
pub struct OnnxEmbedding {
  handle : Int64
  model_path : String
  vocab_path : String
}

///|
pub fn OnnxEmbedding::new(
  model_path : String,
  vocab_path : String,
) -> OnnxEmbedding? {
  let h = _embedding_init(@utf8.encode(model_path), @utf8.encode(vocab_path))
  if h == 0L {
    None
  } else {
    Some({ handle: h, model_path, vocab_path })
  }
}

///|
pub fn OnnxEmbedding::embed(
  self : OnnxEmbedding,
  text : String,
) -> Array[Double]? {
  let dim = _embedding_get(self.handle, @utf8.encode(text))
  if dim <= 0 {
    return None
  }
  let result : Array[Double] = []
  for i = 0; i < dim; i = i + 1 {
    result.push(_embedding_read(self.handle, i))
  }
  Some(result)
}

///|
pub fn OnnxEmbedding::close(self : OnnxEmbedding) -> Unit {
  _embedding_free(self.handle)
}

///|
pub fn create_onnx_provider(
  model_path : String,
  vocab_path : String,
) -> @memory.EmbeddingProviderHandle? {
  match OnnxEmbedding::new(model_path, vocab_path) {
    Some(model) =>
      Some(
        @memory.EmbeddingProviderHandle::create(fn(text) {
          match model.embed(text) {
            Some(v) => v
            None => []
          }
        }),
      )
    None => None
  }
}
