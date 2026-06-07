///|
/// PipelineStore — persistent storage for pipeline segment version/path info.
///
/// In MAF, PipelineStore records which pipeline segments are available,
/// their versions, and file system paths. Used by the qualification
/// system to verify compatibility before activation.

///|
/// PipelineSegmentToken — identifies a segment in the pipeline.
pub enum PipelineSegmentToken {
  Host
  HostSideAdapter
  Contract
  AddInSideAdapter
  AddIn
}

///|
/// SegmentRecord — stored info about one pipeline segment.
pub struct SegmentRecord {
  token : PipelineSegmentToken
  version : String
  path : String
  checksum : String
}

///|
pub fn SegmentRecord::new(
  token : PipelineSegmentToken,
  version : String,
  path : String,
  checksum : String,
) -> SegmentRecord {
  { token, version, path, checksum }
}

///|
/// PipelineStore — in-memory store backed by serialization.
pub struct PipelineStore {
  segments : Map[String, SegmentRecord]
}

///|
pub fn PipelineStore::new() -> PipelineStore {
  { segments: Map([]) }
}

///|
pub fn PipelineStore::register(
  self : PipelineStore,
  record : SegmentRecord,
) -> Unit {
  let key = segment_key(record.token)
  self.segments[key] = record
}

///|
pub fn PipelineStore::resolve(
  self : PipelineStore,
  token : PipelineSegmentToken,
) -> SegmentRecord? {
  self.segments.get(segment_key(token))
}

///|
pub fn PipelineStore::list(self : PipelineStore) -> Array[SegmentRecord] {
  let result : Array[SegmentRecord] = []
  for _, rec in self.segments {
    result.push(rec)
  }
  result
}

///|
pub fn PipelineStore::remove(
  self : PipelineStore,
  token : PipelineSegmentToken,
) -> Unit {
  let key = segment_key(token)
  self.segments.remove(key)
}

///|
pub fn PipelineStore::clear(self : PipelineStore) -> Unit {
  for key, _ in self.segments {
    self.segments.remove(key)
  }
}

///|
fn segment_key(token : PipelineSegmentToken) -> String {
  match token {
    PipelineSegmentToken::Host => "host"
    PipelineSegmentToken::HostSideAdapter => "host_side_adapter"
    PipelineSegmentToken::Contract => "contract"
    PipelineSegmentToken::AddInSideAdapter => "add_in_side_adapter"
    PipelineSegmentToken::AddIn => "add_in"
  }
}
