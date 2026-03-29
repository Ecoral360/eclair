module eclair::route;
import eclair::httpserver;
import eclair::req;
import eclair::res;
import eclair::constants;
import std::collections::map;
import std::io;
import dessert;

struct RouteConfig {
  HTTPMethod method;
  String path;
}

attrdef @Route(RouteConfig config) = @tag("eclair:route", config);

alias RouteHandler = fn void?(Request* req, Response* res);

struct Route {
  String[] path;
  HTTPMethod method;
  RouteHandler handler;
}

fn HashMap{String, String}? Route.match_target(&self, String[] target) {
  HashMap{String, String} map;
  map.init(mem);

  if (target.len != self.path.len) {
    return NOT_FOUND~;
  }

  foreach (i, part : target) {
    String p = self.path[i];
    if (p.len > 0 && p[0] == ':') {
      map.set(p[1..], part);
    } else if (part != p) {
      return NOT_FOUND~;
    }
  }

  return map;
}

<* 
  @require #cb.has_tagof("eclair:route")
  @require $typeof(#cb.tagof("eclair:route")) == RouteConfig
*>
macro Route @to_route(#cb) {
  RouteConfig $config = #cb.tagof("eclair:route");
  var $no_return = $typeof(#cb).returns == void ||| $typeof(#cb).returns == void?;

  var $cb = &#cb;
  var handler = fn void?(Request* req, Response* res) {
    $if $no_return:
      return @call_cb($cb, req, res);

    $else
      var result = @call_cb($cb, req, res);
      $if $defined(result!):
        if (catch result) {
          return;
        }
      $endif

      $switch:
        $case $typeof(result) == String:
          res.set_body(result);

        $case ser::@is_serializable(result):
          res.set_body(ser::serialize(&&json::serializer(), result)!.to_string()!);

      $endswitch

    $endif
  };

  $if $config.path[$config.path.len - 1] == '/':
    var path = $config.path[..$config.path.len - 2];
  $else
    var path = $config.path;
  $endif

  io::printfn("%s %s", $config.method, path);

  return { 
    .path = path.split(mem, "/"),
    .method = $config.method,
    .handler = handler,
  };
}

macro @call_cb($cb, req, res) @local {
  var $params = $typeof($cb).paramsof;

  $switch:
    $case $typeof($cb).paramsof.len == 0:
      return $cb();

    $case $typeof($cb).paramsof.len == 1 &&& $typeof($cb).paramsof[0].type == Request*:
      return $cb(req);
  
    $case $typeof($cb).paramsof.len == 1 &&& $typeof($cb).paramsof[0].type == Response*:
      return $cb(res);

    $default:
      return $cb(req, res);
  $endswitch
}
