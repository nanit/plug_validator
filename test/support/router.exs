defmodule Plug.Support.Router do

  import Plug.Conn
  use Plug.Router
  alias Plug.Support.Router
  plug :match
  plug Plug.Validator, on_error: &Router.on_error_fn/2
  plug :dispatch

  get "/users/:id", private: %{validate: %{id: &Router.validate_integer/1, active: &Router.validate_boolean/1}} do
    json_resp(conn, 200, %{id: 1, name: "user1"})
  end

  def json_resp(conn, status, body) do
    conn |> put_resp_header("content-type", "application/json") |> send_resp(status, Poison.encode!(body))
  end

  def on_error_fn(conn, errors) do
    json_resp(conn, 422, errors) |> halt
  end

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
