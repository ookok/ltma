///|
/// ContractBase — MAF-style contract base class with version marker.
///
/// In MAF, all contracts inherit from a common base that carries
/// pipeline version info. ContractBase adds identity + version + qualifier metadata.

///|
/// ContractSemVer — semantic version for a contract.
pub struct ContractSemVer {
  major : Int
  minor : Int
  patch : Int
}

///|
pub fn ContractSemVer::new(
  major : Int,
  minor : Int,
  patch : Int,
) -> ContractSemVer {
  { major, minor, patch }
}

///|
pub fn ContractSemVer::to_string(self : ContractSemVer) -> String {
  self.major.to_string() +
  "." +
  self.minor.to_string() +
  "." +
  self.patch.to_string()
}

///|
/// ContractBase — version-marked contract identity.
pub struct ContractBase {
  pipeline_version : ContractSemVer
  contract_name : String
  min_host_version : ContractSemVer
}

///|
pub fn ContractBase::create(
  pipeline_version : ContractSemVer,
  contract_name : String,
  min_host_version : ContractSemVer,
) -> ContractBase {
  { pipeline_version, contract_name, min_host_version }
}

///|
pub fn ContractBase::is_compatible(
  self : ContractBase,
  host_version : ContractSemVer,
) -> Bool {
  if self.min_host_version.major != host_version.major {
    return false
  }
  self.min_host_version.minor <= host_version.minor
}

///|
/// VersionInfo — attached to a ContractHandle to advertise its version.
pub struct VersionInfo {
  contract : ContractBase
  handle : ContractHandle
}

///|
pub fn VersionInfo::create(
  contract : ContractBase,
  handle : ContractHandle,
) -> VersionInfo {
  { contract, handle }
}

///|
pub fn VersionInfo::is_compatible(
  self : VersionInfo,
  host_version : ContractSemVer,
) -> Bool {
  self.contract.is_compatible(host_version)
}
