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

And now don't forget to run `mix deps.get`.

Hex docs can be found [here](https://hexdocs.pm/plug_validator/0.1.0/Plug.Validator.html)

## Usage

Let's use a single route `/users/:id` as an example on how we can do in-line validations in a per route basis.

We want to make two validations on the route:

1. Validate the `:id` path parameter is a valid integer
2. Validate the `active` query parameter represents a valid boolean: `"true"`, or `"false"`

All we had to do is declare on the route the validations we want to perform in the following format:

```elixir
%{validate: %{param_name_1: validation_function_1, ... param_name_n: validation_function_n}}
```

So let's see how to apply this in an Elixir and Phoenix project.

### Elixir Project

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

#### Plug Positioning

Pay attention to place the plug right after the call to `plug :match`

Two reasons why this is important:

1. Before `plug :match` is called we don't have path_params on `conn`
2. You want to validate right after the match has been done to avoid running your code on false inputs as soon as possible


### Phoenix Project

Let's take a look at the following Router:

```elixir
defmodule ExampleWeb.Router do
  use ExampleWeb, :router
  require Logger

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    # Add the plug validator
    plug Plug.Validator, on_error: &ExampleWeb.Router.on_error_fn/2
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ExampleWeb do
    pipe_through :browser

    get "/", PageController, :index

    # Enable the plug validator check per route
    get "/users/:id",
        UserController,
        :show,
        private: %{
          validate: %{
            id: &Example.Validator.validate_integer/1,
            active: &Example.Validator.validate_boolean/1
          }
        }

    # Enable the plug validator for a live route
    live "/products/:id",
         ProductsLive,
         private: %{
           validate: %{
             id: &Example.Validator.validate_integer/1,
             active: &Example.Validator.validate_boolean/1
           }
         }
  end

  # This callback is called in case a validation failed
  def on_error_fn(conn, errors) do
    Logger.error(
      "#{__MODULE__} failed to validate route #{conn.request_path} params: #{inspect(errors)}"
    )

    conn
    |> put_status(:not_found)
    |> put_view(ExampleWeb.ErrorView)
    |> render("404.html")
    |> halt()
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExampleWeb do
  #   pipe_through :api
  # end
end

# The dedicated module for validations
defmodule Example.Validator do
  # Two examples for validation functions

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
end
```

> **NOTE**: This is a full working Phoenix router from a fresh `mix phx.new example --no-ecto`, running on Phoenix `1.4.11` and Elixir `1.9.4`.

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

# Contributions

Are welcome :)

