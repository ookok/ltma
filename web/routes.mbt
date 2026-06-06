///|
/// API route definitions for the LTMA web server.

///|
pub enum HttpMethod {
  Get
  Post
  Put
  Delete
}

///|
pub struct Route {
  http_method : HttpMethod
  path : String
  handler_fn : (String) -> String
}

///|
pub fn Route::new(
  http_method : HttpMethod,
  path : String,
  handler_fn : (String) -> String,
) -> Route {
  { http_method, path, handler_fn }
}

///|
pub struct Router {
  routes : Array[Route]
}

///|
pub fn Router::new() -> Router {
  { routes: [] }
}

///|
pub fn Router::add(self : Router, route : Route) -> Unit {
  self.routes.push(route)
}

///|
pub fn Router::dispatch(
  self : Router,
  method_str : String,
  path : String,
  body : String,
) -> String? {
  let http_m = if method_str == "GET" {
    HttpMethod::Get
  } else if method_str == "POST" {
    HttpMethod::Post
  } else if method_str == "PUT" {
    HttpMethod::Put
  } else {
    HttpMethod::Delete
  }
  for route in self.routes {
    if method_match(route.http_method, http_m) && route.path == path {
      return Some((route.handler_fn)(body))
    }
  }
  None
}

///|
fn method_match(a : HttpMethod, b : HttpMethod) -> Bool {
  match (a, b) {
    (HttpMethod::Get, HttpMethod::Get) => true
    (HttpMethod::Post, HttpMethod::Post) => true
    (HttpMethod::Put, HttpMethod::Put) => true
    (HttpMethod::Delete, HttpMethod::Delete) => true
    _ => false
  }
}
