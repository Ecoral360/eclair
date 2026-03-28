module eclair::httpserver;

// ── Opaque types ─────────────────────────────────────────────────────────────
typedef HttpRequest  = void;
typedef HttpResponse = void;
typedef HttpServer   = void;

// ── String type returned by request accessors (NOT null-terminated) ──────────
struct HttpString {
    char* buf;
    int   len;
}

fn String HttpString.to_string(&self) {
  return (String) self.buf[..self.len - 1];
}


// ── Callback aliases ─────────────────────────────────────────────────────────
alias RequestFn       = fn void(HttpRequest*);
alias ChunkCallbackFn = fn void(HttpRequest*);
alias ChunkDoneFn     = fn void(HttpRequest*);

// ── Constants ────────────────────────────────────────────────────────────────
const int HTTP_KEEP_ALIVE  = 1;
const int HTTP_CLOSE       = 0;
const int HTTP_FLG_STREAMED = 0x1;

// ── Server lifecycle ─────────────────────────────────────────────────────────
extern fn HttpServer* http_server_init(int port, RequestFn handler)
    @cname("http_server_init");

extern fn int http_server_listen(HttpServer* server)
    @cname("http_server_listen");

extern fn int http_server_listen_addr(HttpServer* server, char* ipaddr)
    @cname("http_server_listen_addr");

extern fn int http_server_listen_poll(HttpServer* server)
    @cname("http_server_listen_poll");

extern fn int http_server_listen_addr_poll(HttpServer* server, char* ipaddr)
    @cname("http_server_listen_addr_poll");

extern fn int http_server_poll(HttpServer* server)
    @cname("http_server_poll");

extern fn int http_server_loop(HttpServer* server)
    @cname("http_server_loop");

// ── Server userdata ──────────────────────────────────────────────────────────
extern fn void http_server_set_userdata(HttpServer* server, void* data)
    @cname("http_server_set_userdata");

// ── Request accessors ────────────────────────────────────────────────────────
extern fn HttpString http_request_method(HttpRequest* request)
    @cname("http_request_method");

extern fn HttpString http_request_target(HttpRequest* request)
    @cname("http_request_target");

extern fn HttpString http_request_body(HttpRequest* request)
    @cname("http_request_body");

extern fn HttpString http_request_header(HttpRequest* request, char* key)
    @cname("http_request_header");

extern fn int http_request_iterate_headers(
    HttpRequest* request,
    HttpString*  key,
    HttpString*  val,
    int*         iter
) @cname("http_request_iterate_headers");

extern fn int http_request_has_flag(HttpRequest* request, int flag)
    @cname("http_request_has_flag");

// ── Request userdata ─────────────────────────────────────────────────────────
extern fn void  http_request_set_userdata(HttpRequest* request, void* data)
    @cname("http_request_set_userdata");

extern fn void* http_request_userdata(HttpRequest* request)
    @cname("http_request_userdata");

extern fn void* http_request_server_userdata(HttpRequest* request)
    @cname("http_request_server_userdata");

// ── Request connection control ───────────────────────────────────────────────
extern fn void http_request_connection(HttpRequest* request, int directive)
    @cname("http_request_connection");

extern fn void http_request_free_buffer(HttpRequest* request)
    @cname("http_request_free_buffer");

// ── Streaming / chunked request body ────────────────────────────────────────
extern fn void     http_request_read_chunk(HttpRequest* request, ChunkCallbackFn chunk_cb)
    @cname("http_request_read_chunk");

extern fn HttpString http_request_chunk(HttpRequest* request)
    @cname("http_request_chunk");

// ── Response lifecycle ───────────────────────────────────────────────────────
extern fn HttpResponse* http_response_init()
    @cname("http_response_init");

extern fn void http_response_status(HttpResponse* response, int status)
    @cname("http_response_status");

extern fn void http_response_header(HttpResponse* response, char* key, char* value)
    @cname("http_response_header");

extern fn void http_response_body(HttpResponse* response, char* body, int length)
    @cname("http_response_body");

// ── Sending responses ────────────────────────────────────────────────────────
extern fn void http_respond(HttpRequest* request, HttpResponse* response)
    @cname("http_respond");

extern fn void http_respond_chunk(
    HttpRequest*  request,
    HttpResponse* response,
    ChunkDoneFn   notify_done
) @cname("http_respond_chunk");

extern fn void http_respond_chunk_end(HttpRequest* request, HttpResponse* response)
    @cname("http_respond_chunk_end");
