module eclair::router;
import eclair::route;
import eclair::constants;
import std::collections::list;


struct Router {
  String prefix;
  List{Route} routes;
}

fn Router new_router() {
  return {};
}


