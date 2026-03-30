# eclair ⚡

A fast, lightweight web framework for building REST APIs in C3.

## Goal

Eclair aims to make building HTTP APIs in C3 as simple and intuitive as possible, drawing inspiration from modern web frameworks like FastAPI (Python), rocket.rs (Rust), and Express.js (JavaScript). While it takes ideas from these frameworks, eclair is designed specifically for C3 with its own unique approach to routing, middleware, and request handling.

The framework leverages C3's powerful macro system to provide a declarative, attribute-based routing mechanism that feels natural to the language. Whether you're building a small microservice or a larger API, eclair gives you the tools to get started quickly without sacrificing performance.

## Features

- **Declarative Routing**: Define routes using the `@Route` attribute, similar to decorators in FastAPI or attributes in rocket.rs
- **Automatic Parameter Inference**: Simply add parameters to your handler function - types like `int id`, `String name`, or `bool completed` are automatically extracted from path segments, query parameters, or request bodies
- **Automatic Response Handling**: Functions returning `String` or serializable types are automatically sent as JSON responses
- **Path Parameters**: Capture dynamic segments from URLs - just add a matching parameter (e.g., `int id` for `/todos/:id`)
- **Query Parameters**: Access query string parameters - add parameters like `Maybe{bool} completed` for optional query params
- **JSON Body Parsing**: Automatically deserialize JSON request bodies - add a struct parameter and it's automatically parsed
- **Full requset control**: Use a `Request*` parameter to control everything yourself
- **Maybe Types**: Use `Maybe{T}` for optional query parameters and `Maybe{T}` for optional return values (returns JSON or null)
- **Fault Handling**: Make your return type `T?` for error responses with automatic 500 error handling
- **Routers**: Group routes under a common prefix and include them in the server (sub-routers also supported)
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

Get started with eclair: 
1. Make sure you have the [C3 compiler installed](https://github.com/c3lang/c3c)
2. Run `c3c init <YOUR_PROJECT>`
3. Clone this repository into `<YOUR_PROJECT>/lib/eclair.c3l`
4. Clone the [dessert](https://github.com/Ecoral360/dessert) repository into `<YOUR_PROJECT>/lib/dessert.c3l`
5. Add `"dependencies": ["eclair", "dessert"]` to your `project.json`
6. You are done ! Enjoy writing your REST API in C3 !

## How It Works

### The Server

The `Server` struct is the core of eclair. Create a new server with a port number (defaults to 8080):

```c3
Server server = eclair::new_server(); // port will be 8080
Server server = eclair::new_server(5444); // port will be 5444
```

### Routes

Routes are defined using the `@Route` attribute with an HTTP method and path. The macro system automatically handles parameter inference:

```c3
fn String my_handler() @Route({ GET, "/path" }) {
  return "response";
}
```

Handler functions can have parameters automatically inferred:
- `Request*` - The request object
- `Response*` - The response object
- `int`, `String`, `bool`, `char` - Path or query parameters (matching `:param` in path or `param` in query string)
- Any deserializable type (`deserializable struct`, `Maybe{deserializable struct}`, `List{deserializable struct}`, or `deserializable struct[]`) - Automatically parsed from the request body
(see [dessert](https://github.com/Ecoral360/dessert) for more info on deserializable types)
- `Maybe{int | String | bool | char}` - Optional query parameters

Handler functions can return different types:
- `String` - Automatically set as the response body
- Any serializable type (`serializable struct`, `Maybe{serializable struct}`, `List{serializable struct}`, or `serializable struct[]`) - Automatically serialized to JSON
(see [dessert](https://github.com/Ecoral360/dessert) for more info on serializable types)
- `Maybe{T}` - Returns the value as JSON, or `null` if empty
- `T?` - Returns the value as JSON, or 500 error if the handler returns a `fault`
- `void` - Lets the handler function deal with the response

### Path Parameters

Capture dynamic segments from URLs automatically by adding a matching parameter:

```c3
fn Maybe{Todo} get_todo(int id) @Route({ GET, "/todos/:id" }) {
  foreach (todo : todos) {
    if (todo.id == id) {
      return maybe::value{Todo}(todo);  // Wrap value in Maybe
    }
  }
  return {};  // Empty Maybe returns null
}
```

### Query Parameters

Access query string parameters automatically using parameters. Use `Maybe{T}` for optional params:

```c3
fn List{Todo} get_todos(Maybe{bool} completed) @Route({ GET, "/todos" }) {
  // completed is an optional query parameter (?completed=true)
  // Access with `if (try value = completed.get()) { ... }` or `completed.get() ?? default_value`
}
```

### JSON Request Bodies

Request bodies are automatically deserialized from JSON by adding a deserializable struct parameter:

```c3
fn Todo? create_todo(TodoInput input) @Route({ POST, "/todos" }) {
  // TodoInput is automatically parsed from the request body
  // ...
}
```

### Routers

Group routes under a common prefix using routers:

```c3
fn void main() {
  // ...
  Router todo_router = router::new_router("/todos");
  todo_router.@add_route(get_todos);
  todo_router.@add_route(create_todo);
  todo_router.@add_route(get_todo);
  todo_router.@add_route(update_todo);
  todo_router.@add_route(delete_todo);

  server.include_router(todo_router);
}
```

### Request and Response

The `Request` and `Response` types give you access to the HTTP transaction:

```c3
fn void handler(Request* req, Response* res) @Route({ GET, "/example" }) {
  // Access request data
  String target = req.target();
  HTTPMethod method = req.method();
  String body = req.body();

  // Set response
  res.set_status(200);
  res.set_body("Hello, world!");
}
```

### Fault Handling

Return faults for error responses. The framework automatically handles them:

```c3
fn Todo? get_todo(int id) @Route({ GET, "/todos/:id" }) {
  foreach (todo : todos) {
    if (todo.id == id) {
      return todo;
    }
  }
  return NOT_FOUND~;  // Returns 500 error
}
```

## Complete Example

See [todo.c3](todo.c3) for a full REST API example with CRUD operations:

```c3
module example::todo;

import std;
import eclair;
import dessert;
import json;

struct Todo {
  int id;
  String title;
  bool completed;
}

fn void? Todo.serialize(&self, Serializer serializer) =>
  ser::impl_serialize(self, serializer);

fn void? Todo.deserialize(&self, Deserializer deserializer) =>
  des::impl_deserialize(self, deserializer);

struct TodoInput {
  String title;
  bool completed;
}

fn void? TodoInput.serialize(&self, Serializer serializer) =>
  ser::impl_serialize(self, serializer);

fn void? TodoInput.deserialize(&self, Deserializer deserializer) =>
  des::impl_deserialize(self, deserializer);

// Query parameter - optional (?completed=true or ?completed=false)
fn List{Todo} get_todos(Maybe{bool} completed) @Route({ GET, "/" }) { /* ... */ }

// Body parameter - inferred from JSON request body
fn Todo? create_todo(TodoInput input) @Route({ POST, "/" }) { /* ... */ }

// Path parameter - matches :id in route
fn Maybe{Todo}? get_todo(int id) @Route({ GET, "/:id" }) { /* ... */ }

// Multiple parameters combined
fn Todo? update_todo(int id, TodoInput input) @Route({ PUT, "/:id" }) { /* ... */ }

// Manual approach still supported
fn Todo? delete_todo(Request* req) @Route({ DELETE, "/:id" }) {
  int id = req.params["id"].to_int()!;
  // ...
}

fn String hello(Maybe{String} name) @Route({ GET, "/hello" }) {
  return string::format(mem, "Hello, %s!", name.get() ?? "Stranger");
}

fn int main(String[] args) {
  Server server = eclair::new_server();
  server.@add_route(hello);

  Router todo_router = router::new_router("/todos");
  todo_router.@add_route(get_todos);
  todo_router.@add_route(create_todo);
  todo_router.@add_route(get_todo);
  todo_router.@add_route(update_todo);
  todo_router.@add_route(delete_todo);

  server.include_router(todo_router);
  server.listen();
  return 0;
}
```

## Backend

Eclair uses [httpserver.h](https://github.com/jeremycw/httpserver.h) as its HTTP server backend. This is a minimal, fast C library that handles the low-level socket communication and HTTP parsing, allowing eclair to focus on providing a pleasant API surface.

## Why the name eclair ?

`Eclair` has two meaning. 
1. It means lightning in French and represents the goal of making it as fast to write in as possible.
2. The deserializer and serializer lib used by eclair is [dessert](https://github.com/Ecoral360/dessert) and `eclair (au chocolat)` is a pastry.

## License

MIT
