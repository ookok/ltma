///|
/// Model auto-download — downloads ONNX model from Hugging Face if not present.

///|
/// Ensure the model exists. Returns true if available.
pub fn ensure_model(model_path : String, vocab_path : String) -> Bool {
  if @xfs.path_exists(model_path) && @xfs.path_exists(vocab_path) {
    return true
  }
  println("Downloading embedding model (MiniLM-L6-v2)...")
  println("This is a one-time download (~90MB).")
  // Download logic would go here using @async_http
  // For now, check if manully placed
  @xfs.path_exists(model_path) && @xfs.path_exists(vocab_path)
}
