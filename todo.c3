module example::todo;

import std::io;
import eclair;
import eclair::route;
import dessert::ser;
import dessert::des;
import dessert::json;
import json;
import std::collections::list;
import std::collections::maybe;

struct Todo (Serializable, Deserializable) {
    int id;
    String title;
    bool completed;
}

fn void? Todo.serialize(&self, Serializer serializer) @dynamic =>
    ser::impl_serialize(serializer, self);

fn void? Todo.deserialize(&self, Deserializer deserializer) @dynamic =>
    des::impl_deserialize(deserializer, self);

struct TodoInput (Serializable, Deserializable) {
    String title;
    bool completed;
}

fn void? TodoInput.serialize(&self, Serializer serializer) @dynamic =>
    ser::impl_serialize(serializer, self);

fn void? TodoInput.deserialize(&self, Deserializer deserializer) @dynamic =>
    des::impl_deserialize(deserializer, self);

List{Todo} todos;

fn String get_todos() @Route({ GET, "/todos" }) {
    JsonValue? json = ser::serialize(&json::serializer(), todos);
    if (catch json) {
        return "[]";
    }
    return json.print()!!;
}

fn String create_todo(Request* req) @Route({ POST, "/todos" }) {
    TodoInput? input = req.json_body_as{TodoInput}();
    if (catch input) {
        return "Invalid request body";
    }

    int new_id = todos.len() + 1;
    Todo new_todo = { .id = new_id, .title = input.title, .completed = input.completed };
    todos.push(new_todo);

    JsonValue? json = ser::serialize(&json::serializer(), new_todo);
    if (catch json) {
        return "{}";
    }
    return json.print()!!;
}

fn String get_todo(Request* req) @Route({ GET, "/todos/:id" }) {
    String path = req.target();
    String[] parts = path.split("/");
    if (parts.len < 3) {
        return "Invalid request";
    }

    int id = parts[2].to_int()!;
    foreach (todo : todos) {
        if (todo.id == id) {
            JsonValue? json = ser::serialize(&json::serializer(), todo);
            if (catch json) {
                return "{}";
            }
            return json.print()!!;
        }
    }
    return "{}";
}

fn String update_todo(Request* req) @Route({ PUT, "/todos/:id" }) {
    String path = req.target();
    String[] parts = path.split("/");
    if (parts.len < 3) {
        return "Invalid request";
    }

    int id = parts[2].to_int()!;
    TodoInput? input = req.json_body_as{TodoInput}();
    if (catch input) {
        return "Invalid request body";
    }

    foreach (i, todo : todos) {
        if (todo.id == id) {
            todos.get(i).id = id;
            todos.get(i).title = input.title;
            todos.get(i).completed = input.completed;

            JsonValue? json = ser::serialize(&json::serializer(), todos.get(i));
            if (catch json) {
                return "{}";
            }
            return json.print()!!;
        }
    }
    return "{}";
}

fn String delete_todo(Request* req) @Route({ DELETE, "/todos/:id" }) {
    String path = req.target();
    String[] parts = path.split("/");
    if (parts.len < 3) {
        return "Invalid request";
    }

    int id = parts[2].to_int()!;
    foreach (i, todo : todos) {
        if (todo.id == id) {
            todos.remove(i);
            return "Deleted";
        }
    }
    return "Not found";
}

fn int main(String[] args) {
    Server server = eclair::new_server();
    server.@add_route(get_todos);
    server.@add_route(create_todo);
    server.@add_route(get_todo);
    server.@add_route(update_todo);
    server.@add_route(delete_todo);

    server.listen();
    return 0;
}
