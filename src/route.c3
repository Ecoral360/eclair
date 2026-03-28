module eclair::route;
import eclair::httpserver;
import eclair::req;
import eclair::res;
import eclair::constants;

struct RouteConfig {
  HTTPMethod method;
  String path;
}

attrdef @Route(RouteConfig config) = @tag("eclair:route", config);

alias RouteHandler = fn void(Request* req, Response* res);

struct Route {
  String path;
  HTTPMethod method;
  RouteHandler handler;
}

<* 
  @require $defined(#cb()) 
  @require #cb.has_tagof("eclair:route")
  @require $typeof(#cb.tagof("eclair:route")) == RouteConfig
*>
macro Route @to_route(#cb) {
  RouteConfig $config = #cb.tagof("eclair:route");

  var $cb = &#cb;
  var handler = fn void(Request* req, Response* res) {
    $switch:
      $case $typeof($cb).paramsof.len == 0:
        var result = $cb();

      $case $typeof($cb).paramsof.len == 1 &&& $typeof($typeof($cb).paramsof[0]) == Request*:
        var result = $cb(req);
    
      $case $typeof($cb).paramsof.len == 1 &&& $typeof($typeof($cb).paramsof[0]) == Response*:
        var result = $cb(res);

      $default:
        var result = $cb(req, res);
    $endswitch
    
    $switch:
      $case $typeof(result) == String:
        res.set_body(result);
    $endswitch
  };

  return { 
    .path = $config.path, 
    .method = $config.method,
    .handler = handler,
  };
}

<* 
  @require $defined($cb()) 
*>
macro Route route($cb, RouteConfig $config) {
  var handler = fn void(Request* req, Response* res) {
    $switch:
      $case $typeof($cb).paramsof.len == 0:
        var result = $cb();

      $case $typeof($cb).paramsof.len == 1 &&& $typeof($typeof($cb).paramsof[0]) == Request*:
        var result = $cb(req);
    
      $case $typeof($cb).paramsof.len == 1 &&& $typeof($typeof($cb).paramsof[0]) == Response*:
        var result = $cb(res);

      $default:
        var result = $cb(req, res);
    $endswitch
    
    $switch:
      $case $typeof(result) == String:
        res.set_body(result);
    $endswitch
  };


  return { 
    .path = $config.path, 
    .method = $config.method,
    .handler = handler,
  };
}
