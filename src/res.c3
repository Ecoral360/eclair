module eclair::res;
import eclair::httpserver;

struct Response {
  HttpResponse* inner;
}


fn Response new_response() {
  HttpResponse* res = httpserver::http_response_init();
  return { .inner = res };
}

fn void Response.set_status(&self, int status) {
  httpserver::http_response_status(self.inner, status);
}

fn void Response.set_body(&self, String body) {
  httpserver::http_response_body(self.inner, body, body.len);
}

