module eclair::route;
import eclair::httpserver;
import eclair::req;
import eclair::res;
import eclair::constants;
import dessert;

struct RouteConfig {
  HTTPMethod method;
  String path;
}

attrdef @Route(RouteConfig config) = @tag("eclair:route", config);

alias RouteHandler = fn void?(Request* req, Response* res);

struct Route {
  String path;
  HTTPMethod method;
  RouteHandler handler;
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

  return { 
    .path = $config.path, 
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

// macro @handle_post_params($cb, req, res) @local {
//   var $params = $typeof($cb).paramsof;
//   var $final_params = {};
//
//   $foreach $i, $param : $params :
//     $switch:
//       $case $param.type == Request*:
//         $final_params += {req};
//     
//       $case $param.type == Response*:
//         $final_params +++= res;
//     $endswitch
//   $endforeach
//
//
//   return $cb();
// }

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
