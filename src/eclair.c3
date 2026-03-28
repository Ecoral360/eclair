module eclair;
import eclair::httpserver;
import std::io;
import std::collections::list;
import eclair::route;

struct Server {
  HttpServer *server;
  int port;
}

List{Route} routes;

fn void init_routes() @local @init {
  routes.init(mem);
}
fn void free_routes() @local @finalizer {
  routes.free();
}

fn void request_handler(HttpRequest* _req) @private {
  Request req = req::request_from(_req);

  Response res = res::new_response();
  String target = req.target();
  HTTPMethod method = req.method()!!;

  foreach (route : routes) {
    if (route.path == target && route.method == method) {
      route.handler(&req, &res)!!;
      break;
    }
  }

  httpserver::http_respond(req.inner, res.inner);
}

fn Server new_server(int port = 8080) {
  return { 
    .server = httpserver::http_server_init(port, &request_handler), 
    .port = port, 
  };
}

fn void Server.add_route(&self, Route route) {
  routes.push(route);
}

macro void Server.@add_route(&self, #route) {
  routes.push(route::@to_route(#route));
}

fn void Server.listen(&self) {
  io::printfn("Listening on %s", self.port);
  httpserver::http_server_listen(self.server);
}




