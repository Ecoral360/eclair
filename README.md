# eclair ⚡

A fast, lightweight web framework for building REST APIs in C3.

## Goal

Eclair aims to make building HTTP APIs in C3 as simple and intuitive as possible, drawing inspiration from modern web frameworks like FastAPI (Python), rocket.rs (Rust), and Express.js (JavaScript). While it takes ideas from these frameworks, eclair is designed specifically for C3 with its own unique approach to routing, middleware, and request handling.

The framework leverages C3's powerful macro system to provide a declarative, attribute-based routing mechanism that feels natural to the language. Whether you're building a small microservice or a larger API, eclair gives you the tools to get started quickly without sacrificing performance.

## Features

- **Declarative Routing**: Define routes using the `@Route` attribute, similar to decorators in FastAPI or attributes in rocket.rs
- **Automatic Response Handling**: Functions returning `String` are automatically sent as response bodies
- **Flexible Handlers**: Define handlers with zero, one, or two parameters (`Request*`, `Response*`, or both)
- **HTTP Method Support**: Support for all standard HTTP methods (GET, POST, PUT, DELETE, PATCH, etc.)
- **C Interop**: Built on top of [httpserver.h](https://github.com/jeremycw/httpserver.h), a minimal C HTTP server library

## Quick Start

```c3
module example;

import std::io;
import eclair;
import eclair::route;

fn String hello() @Route({ GET, "/hello" }) {
  return "Hello world!\n";
}

fn void api_status(Request* req, Response* res) @Route({ GET, "/status" }) {
  res.set_body("OK");
}

fn int main(String[] args) {
  Server server = eclair::new_server();
  server.@add_route(hello);
  server.@add_route(api_status);

  server.listen();
  return 0;
}
```

## Installation

Eclair is a C3 project that depends on the [httpserver.h](https://github.com/jeremycw/httpserver.h) C library. Make sure you have C3 and a C compiler installed, then clone this repository and build your project with the eclair module.

## How It Works

### The Server

The `Server` struct is the core of eclair. Create a new server with a port number (defaults to 8080):

```c3
Server server = eclair::new_server(8080);
```

### Routes

Routes are defined using the `@Route` attribute with an HTTP method and path. The macro system automatically wraps your handler function to match the expected signature:

```c3
fn String my_handler() @Route({ GET, "/path" }) {
  return "response";
}
```

Handler functions can return different types:
- `String` - Automatically set as the response body
- `void` - Manual response handling via `Response*`

### Request and Response

The `Request` and `Response` types give you access to the HTTP transaction:

```c3
fn void handler(Request* req, Response* res) @Route({ GET, "/example" }) {
  // Access request data
  String target = req.target();
  HTTPMethod method = req.method()!!;

  // Set response
  res.set_body("Hello, world!");
}
```

## Backend

Eclair uses [httpserver.h](https://github.com/jeremycw/httpserver.h) as its HTTP server backend. This is a minimal, fast C library that handles the low-level socket communication and HTTP parsing, allowing eclair to focus on providing a pleasant API surface.


## Why the name eclair ?

`Eclair` has two meaning. 
1. It means lightning in French and represents the goal of making it as fast as possible.
2. The deserializer and serializer lib used by eclair is [dessert](https://github.com/Ecoral360/dessert) and `eclair au chocolat` is a pastry.

## License

MIT
