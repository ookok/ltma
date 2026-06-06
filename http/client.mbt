///|
/// HTTP client abstraction.

///|
pub struct HttpMethod {
  code : Int
}

///|
pub fn HttpMethod::get() -> HttpMethod {
  { code: 0 }
}

///|
pub fn HttpMethod::post() -> HttpMethod {
  { code: 1 }
}

///|
pub struct HttpRequest {
  http_method : HttpMethod
  url : String
  headers : Map[String, String]
  body : String?
}

///|
pub fn HttpRequest::post(
  url : String,
  body : String,
  api_key : String,
) -> HttpRequest {
  {
    http_method: HttpMethod::post(),
    url,
    headers: Map([
      ("Content-Type", "application/json"),
      ("Authorization", "Bearer \{api_key}"),
    ]),
    body: Some(body),
  }
}

///|
pub struct HttpResponse {
  status : Int
  body : String
}

///|
pub fn HttpResponse::new(status : Int, body : String) -> HttpResponse {
  { status, body }
}

///|
/// Mock HTTP client for testing
pub struct MockHttpClient {
  resp : HttpResponse
}

///|
pub fn MockHttpClient::new(resp : HttpResponse) -> MockHttpClient {
  { resp, }
}

///|
pub fn MockHttpClient::request(
  self : MockHttpClient,
  _req : HttpRequest,
) -> HttpResponse {
  self.resp
}
