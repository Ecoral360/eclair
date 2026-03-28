module eclair::req;
import eclair::httpserver;
import eclair::constants;

struct Request {
  HttpRequest* inner;
}

fn Request request_from(HttpRequest* req) {
  return { .inner = req };
}

fn String Request.target(&self) {
  return httpserver::http_request_target(self.inner).to_string();
}

fn HTTPMethod? Request.method(&self) {
  String method_name = httpserver::http_request_method(self.inner).to_string();
  return HTTPMethod.lookup_field(name, method_name);
}
