Plug is an Elixir specification for composabe modules between web application. That's a very nice way to describe a middleware.
For those of you that come from the Ruby world it pretty much takes the role of Rack middlewares.
A few weeks ago I searched Google for a Plug library to validate path and query params declaratively on the router.
I got a single result https://github.com/KamilLelonek/plug-validation but it doesn't have any documentation and from going over the code it didn't provide what I was looking for.
In my vision I would write the routes as:
```elixir
  get "/users/:id", private: %{validate: %{id: &validate_integer/1, active: &validate_boolean/1}} do
```
This would validate that the path param `id` is a valid integer and that the query param `active` is a valid boolean string value (either "true" or "false").
The library should accept a callback to run when a validation fails. This callback is user defined and might, for example, return a 422 status code.

I had the need, I had the vision. I decided to write my own Plug library.

# Starting a new project

To start a fresh elixir project we type
```
mix new plug_validator --module Plug.Validator
```

The default module name would have been `PlugValidator`. I mentioned it explictly to follow the pattern of `Plug.Router` and friends.
To complete the initial files structure I created some directories and moved some files:
```
mkdir lib/plug
mv lib/plug_validator.ex lib/plug/validator.ex
mkdir test/plug
mv test/plug_validator.ex test/plug/validator.ex
```
Just to make sure everything is intact we can run
```
mix test
```

And see that the tests passes and we haven't broken anything.

# TDD

When I start with a clear vision of what I would like to have, I tend to go TDD.
TDD is a shortcut for Test Driven Development. It means that you write the tests for the function/module you are about to create before you write the actual code.
The first thing I did was to create a dummy router and some validation functions to work with. Two important decisions I made in this stage:

1. `Plug.Validator` should be inserted between `plug :match` and `plug :dispatch`. This is to ensure we only run the validation function only _after_ the route has been matched.
2. A validation function should return `{:error, the_error}` in case of falied validation. Any other value returned indicates the validation passed.
3. The validation declaration will be made in the `private` storage of `Conn`. As the documentation states: "This storage is meant to be used by libraries and frameworks to avoid writing to the user storage"

I thought the appropriate path to put these files in is *test/support/* since they do not contain any tests per-se.
```elixir
defmodule Plug.Support.Router do

  import Plug.Conn
  import Plug.Support.Validators, only: [validate_integer: 1, validate_boolean: 1, on_error_fn: 2, json_resp: 3]
  use Plug.Router

  plug :match
  plug Plug.Validator, on_error: &on_error_fn/2
  plug :dispatch

  get "/users/:id", private: %{validate: %{id: &validate_integer/1, active: &validate_boolean/1}} do
    json_resp(conn, 200, %{id: 1, name: "user1"})
  end
end
```
The dummy router shows exactly how the plug validator should be used.
We use `plug Plug.Validator` between the match and dispatch plugs. We also provide an error callback that will receive the `conn` and error list in case of a failed validation.
The route definition itself uses the `private` storage of `Conn` to hold the required validations. 
```elixir
defmodule Plug.Support.Validators do
  import Plug.Conn

  def validate_integer(v) do
    case Integer.parse(v) do
      :error -> {:error, "could not parse #{v} as integer"}
      other -> other
    end
  end

  def validate_boolean(v) do
    case v do
      nil -> false
      "true" -> true
      "false" -> false
      _other -> {:error, "could not parse #{v} as boolean"}
    end
  end

  def on_error_fn(conn, errors) do
    json_resp(conn, 422, errors) |> halt
  end

  def json_resp(conn, status, body) do
    conn |> put_resp_header("content-type", "application/json") |> send_resp(status, Poison.encode!(body))
  end
  
end
```
I created two very simple validations for integers and boolean values. I also created an error callback that returns a 422 status code and halts Plug's pipeline execution.

Now that we created the support files we should add them to `test/test_helpers.exs` since everything under `test/support/*` is not loaded by default.
```elixir
Code.load_file("test/support/validators.exs")
Code.load_file("test/support/router.exs")
ExUnit.start()
```

So much code and still not a single line to implement the Plug's functionality.
All I did until now is to create a client code for my Plug. By starting from the client-side code I describe how I, as a developer, would have liked to use the library. For me, being able to feel how my library is going to be used before I even created it is priceless. It makes me focus on exactly what my library needs to do and puts the developer who uses it in top priority. It also allows me to iterate on the interface to make it as confortable and natural as possible before I even wrote a single line of code.
The last step before I go on to implement the functionality is to create a test against this dummy router. I decided to create all the tests and not do it iteratively as TDD suggests because I felt they were trivial enough.

```elixir
defmodule Plug.ValidatorTest do
  use ExUnit.Case
  use Plug.Test

  @subject Plug.Support.Router

  @opts @subject.init([])

  def assert_json_response(request_url, expected_status, expected_body) do 
    conn = conn(:get, request_url)
    conn = @subject.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == expected_status
    body = Poison.decode!(conn.resp_body, keys: :atoms)
    assert body == expected_body
  end

  test "valid request" do
    assert_json_response("/users/1?active=true", 200, %{id: 1, name: "user1"})
  end

  test "invalid path params" do
    assert_json_response("/users/not-an-integer", 422, %{id: "could not parse not-an-integer as integer"})
  end

  test "multiple invalid params" do
    assert_json_response("/users/not-an-integer?active=not-a-boolean", 
                         422, 
                         %{id: "could not parse not-an-integer as integer", active: "could not parse not-a-boolean as boolean"})
  end

  test "one valid one invalid" do
    assert_json_response("/users/1?active=not-a-boolean", 422, %{active: "could not parse not-a-boolean as boolean"})
  end
end


```
As you can see, the tests are pretty straight forward. I first check for a valid request and then take a few examples of invalid parameters.
