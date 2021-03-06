# Plug.Validator

A minimal Plug to validate input path/query params in declarative way on your routers.

## Installation

The package can be installed by adding `plug_validator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plug_validator, "~> 0.1.0"}
  ]
end
```

Hex docs can be found [here](https://hexdocs.pm/plug_validator/0.1.0/Plug.Validator.html)

## Usage

Let's take a look at the following Router:

```elixir
defmodule Plug.Support.Router do

  import Plug.Conn
  use Plug.Router
  alias Plug.Support.Router
  plug :match

  # Insert the Plug.Validator right after the plug :match
  plug Plug.Validator, on_error: &Router.on_error_fn/2

  plug :dispatch

  get "/users/:id", private: %{validate: %{id: &Router.validate_integer/1, active: &Router.validate_boolean/1}} do
    json_resp(conn, 200, %{id: 1, name: "user1"})
  end

  # This callback is called in case a validation failed

  defp on_error_fn(conn, errors) do
    json_resp(conn, 422, errors) |> halt
  end

  # Two examples for validation functions

  defp validate_integer(v) do
    case Integer.parse(v) do
      :error -> {:error, "could not parse #{v} as integer"}
      other -> other
    end
  end

  defp validate_boolean(v) do
    case v do
      nil -> false
      "true" -> true
      "false" -> false
      _other -> {:error, "could not parse #{v} as boolean"}
    end
  end

  defp json_resp(conn, status, body) do
    conn |> put_resp_header("content-type", "application/json") |> send_resp(status, Poison.encode!(body))
  end
  
end

```
The example shows a single route `/users/:id`.

We want to make two validations on the route:

1. Validate the `:id` path parameter is a valid integer
2. Validate the `active` query parameter represents a valid boolean: `"true"`, or `"false"`

All we had to do is declare the validations we want to perform in the following format:

```elixir
%{validate: %{param_name_1: validation_function_1, ... param_name_n: validation_function_n}}
```

To the route declaration.

## Validator Functions

A validator function is a function that:

1. Operates on a single value
2. Returns `{:error, reason}` in case the value did not pass validation
3. Returns any other value in case the value did pass validation

The above example has two validator function examples: `validate_integer/1` and `validate_boolean/1`

## Errors Structure

The validation procedure traverses the `validate` map you provided and returns the following structure:

```elixir
%{param_name_1: error_message_1, ...., param_name_n: error_message_n}
```

In case all parameters were validated successfully, the errors map is returned as an empty map.

## On Error Callback

The on error callback is called if one of the validation failed.
It is your responsibility to implement it and supply it as the `on_error` option to the Plug.

You error callback will be called on the `conn` object and the errors map.
The above implementation, `on_error_fn`, just returns a `422` status code with the errors map as body.

## Plug Positioning

Pay attention to place the plug right after the call to `plug :match`

Two reasons why this is important:

1. Before `plug :match` is called we don't have path_params on `conn`
2. You want to validate right after the match has been done to avoid running your code on false inputs as soon as possible

# Contributions

Are welcome :)

