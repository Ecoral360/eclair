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

fn List{Todo} get_todos(Request* req) @Route({ GET, "/" }) {
  return todos;
}

fn Todo? create_todo(Request* req) @Route({ POST, "/" }) {
  TodoInput input = req.json_body_as(TodoInput)!;

  usz new_id = todos.len() + 1;
  Todo new_todo = { .id = (int) new_id, .title = input.title, .completed = input.completed };
  todos.push(new_todo);

  return new_todo;
}

fn Maybe{Todo}? get_todo(Request* req) @Route({ GET, "/:id" }) {
  int id = req.params["id"].to_int()!;
  foreach (todo : todos) {
    if (todo.id == id) {
      return maybe::value{Todo}(todo);
    }
  }
  return {};
}

fn Todo? update_todo(Request* req) @Route({ PUT, "/:id" }) {
  TodoInput input = req.json_body_as(TodoInput)!;

  int id = req.params["id"].to_int()!;
  foreach (todo : &todos) {
    if (todo.id == id) {
      todo.id = id;
      todo.title = input.title;
      todo.completed = input.completed;

      return todo;
    }
  }
  return NOT_FOUND~;
}

fn Todo? delete_todo(Request* req) @Route({ DELETE, "/:id" }) {
  int id = req.params["id"].to_int()!;
  foreach (i, todo : todos) {
    if (todo.id == id) {
      todos.remove_at(i);
      return todo;
    }
  }
  return NOT_FOUND~;
}

fn String hello(Request* req) @Route({ GET, "/hello" }) {
  String name = req.query["name"] ?? "Stranger";
  return string::format(mem, "Hello, %s!", name);
}

/// MAIN PROGRAM

List{Todo} todos;

fn void init_list() @init {
  todos.init(mem);
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
