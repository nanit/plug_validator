defmodule Plug.Support.Router do

  import Plug.Conn
  use Plug.Router
  import Plug.Support.Validators, only: [validate_integer: 1, validate_boolean: 1, on_error_fn: 2, json_resp: 3]
  plug :match
  plug Plug.Validator, on_error: &on_error_fn/2
  plug :dispatch

  get "/users/:id", private: %{validate: %{id: &validate_integer/1, active: &validate_boolean/1}} do
    json_resp(conn, 200, %{id: 1, name: "user1"})
  end
end
