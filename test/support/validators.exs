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
