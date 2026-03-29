module eclair::constants;

enum HTTPMethod : (String name) {
  GET { "GET" },
  HEAD { "HEAD" },
  OPTIONS { "OPTIONS" },
  TRACE { "TRACE" },
  PUT { "PUT" },
  DELETE { "DELETE" },
  POST { "POST" },
  PATCH { "PATCH" },
  CONNECT { "CONNECT" },
}
