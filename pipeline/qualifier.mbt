///|
/// PipelineQualifier — MAF-style pipeline segment compatibility verification.
///
/// In MAF, a PipelineQualifier checks that the pipeline segments
/// (Host → HostSideAdapter → Contract → AddInSideAdapter → AddIn)
/// are compatible in terms of versioning and expected capabilities.

///|
/// QualificationLevel — how strict the compatibility check is.
pub enum QualificationLevel {
  /// Exact version match required.
  Strict
  /// Major version must match, minor can differ.
  Compatible
  /// Any version accepted with warning.
  Loose
}

///|
/// QualificationResult — outcome of a qualification check.
pub struct QualificationResult {
  passed : Bool
  message : String
  level : QualificationLevel
}

///|
pub fn QualificationResult::passed(
  level : QualificationLevel,
) -> QualificationResult {
  { passed: true, message: "", level }
}

///|
pub fn QualificationResult::failed(
  level : QualificationLevel,
  msg : String,
) -> QualificationResult {
  { passed: false, message: msg, level }
}

///|
/// Check contract compatibility between two versions.
pub fn check_contract(
  host_version : String,
  contract_version : String,
  level : QualificationLevel,
) -> QualificationResult {
  match level {
    QualificationLevel::Strict =>
      if host_version == contract_version {
        QualificationResult::passed(level)
      } else {
        QualificationResult::failed(
          level,
          "version mismatch: host=\{host_version} contract=\{contract_version}",
        )
      }
    QualificationLevel::Compatible =>
      if get_major(host_version) == get_major(contract_version) {
        QualificationResult::passed(level)
      } else {
        QualificationResult::failed(
          level,
          "major version mismatch: host=\{host_version} contract=\{contract_version}",
        )
      }
    QualificationLevel::Loose => QualificationResult::passed(level)
  }
}

///|
/// Check that an agent's metadata capabilities are compatible with the host.
pub fn check_capabilities(
  required : Array[String],
  provided : Array[String],
) -> QualificationResult {
  for req in required {
    let mut found = false
    for prov in provided {
      if req == prov {
        found = true
        break
      }
    }
    if !found {
      return QualificationResult::failed(
        QualificationLevel::Strict,
        "missing capability: \{req}",
      )
    }
  }
  QualificationResult::passed(QualificationLevel::Strict)
}

///|
/// Extract major version from "x.y.z" format.
fn get_major(version : String) -> String {
  match version.find(".") {
    Some(idx) => version.sub(start=0, end=idx).to_owned()
    None => version
  }
}
