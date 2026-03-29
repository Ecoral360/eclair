module eclair;
import eclair::httpserver;
import std::io;
import std::collections::list;
import std::collections::map;
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
  HashMap{String, String} query;
  query.init(mem);
  defer query.free();

  if (target.contains("?")) {
    usz idx = target.index_of_char('?')!!;
    String query_str = target[idx + 1..];
    target = target[..idx - 1];
    foreach (query_arg : query_str.split(mem, "&")) {
      if (query_arg.contains("=")) {
        usz eq_idx = query_arg.index_of_char('=')!!;
        String query_key = query_arg[..eq_idx - 1];
        String query_val = query_arg[eq_idx + 1..];
        query.set(query_key, query_val);
      }
    }
  }

  if (target[target.len - 1] == '/') {
    target = target[..target.len - 2];
  }
  String[] parts = target.split(mem, "/");

  foreach (route : routes) {
    if (method != route.method) continue;
    if (try params = route.match_target(parts)) {
      req.params = params;
      if (catch route.handler(&req, &res)) {
        io::printfn("Error handling the request at route '%s'", target);
        res.set_status(500);
        break;
      }
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




