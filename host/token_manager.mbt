///|
/// Token Manager — inter-agent authentication and authorization tokens.

///|
/// AccessToken — proof of identity for inter-agent calls.
pub struct AccessToken {
  issuer : String
  subject : String
  capabilities : Array[String]
  mut expired : Bool
}

///|
pub fn AccessToken::new(
  issuer : String,
  subject : String,
  capabilities : Array[String],
) -> AccessToken {
  { issuer, subject, capabilities, expired: false }
}

///|
pub fn AccessToken::has_capability(self : AccessToken, cap : String) -> Bool {
  for c in self.capabilities {
    if c == cap {
      return true
    }
  }
  false
}

///|
pub fn AccessToken::invalidate(self : AccessToken) -> Unit {
  self.expired = true
}

///|
pub fn AccessToken::is_valid(self : AccessToken) -> Bool {
  !self.expired
}

///|
/// TokenManager — issues and validates access tokens.
pub struct TokenManager {
  secrets : Map[String, String]
  issued_tokens : Map[String, AccessToken]
}

///|
pub fn TokenManager::new() -> TokenManager {
  { secrets: Map([]), issued_tokens: Map([]) }
}

///|
pub fn TokenManager::register_secret(
  self : TokenManager,
  agent_name : String,
  secret : String,
) -> Unit {
  self.secrets[agent_name] = secret
}

///|
pub fn TokenManager::issue_token(
  self : TokenManager,
  issuer : String,
  subject : String,
  capabilities : Array[String],
) -> String? {
  match self.secrets.get(issuer) {
    Some(_secret) => {
      let token = AccessToken::new(issuer, subject, capabilities)
      let token_id = issuer +
        ":" +
        subject +
        ":" +
        self.issued_tokens.length().to_string()
      self.issued_tokens[token_id] = token
      Some(token_id)
    }
    None => None
  }
}

///|
pub fn TokenManager::validate(
  self : TokenManager,
  token_id : String,
) -> AccessToken? {
  match self.issued_tokens.get(token_id) {
    Some(token) => if token.is_valid() { Some(token) } else { None }
    None => None
  }
}

///|
pub fn TokenManager::revoke(self : TokenManager, token_id : String) -> Unit {
  match self.issued_tokens.get(token_id) {
    Some(token) => token.invalidate()
    None => ()
  }
}

///|
pub fn TokenManager::revoke_all(
  self : TokenManager,
  agent_name : String,
) -> Unit {
  for id, token in self.issued_tokens {
    if token.issuer == agent_name || token.subject == agent_name {
      token.invalidate()
    }
  }
}
