defmodule Plug.ValidatorTest do
  use ExUnit.Case
  doctest Plug.Validator
  use Plug.Test

  @subject Plug.Support.Router

  @opts @subject.init([])

  test "valid request" do
    conn = conn(:get, "/users/1?active=true")
    conn = @subject.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert Poison.decode!(conn.resp_body, keys: :atoms) == %{id: 1, name: "user1"}
  end

  test "invalid path params" do
    conn = conn(:get, "/users/not-an-integer")
    conn = @subject.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 422
    assert Poison.decode!(conn.resp_body, keys: :atoms) == %{id: "could not parse not-an-integer as integer"}
  end

  test "multiple invalid path params" do

    conn = conn(:get, "/users/not-an-integer?active=not-a-boolean")
    conn = @subject.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 422
    assert Poison.decode!(conn.resp_body, keys: :atoms) == %{id: "could not parse not-an-integer as integer", active: "could not parse not-a-boolean as boolean"}
  end

  test "on valid one invalid" do

    conn = conn(:get, "/users/1?active=not-a-boolean")
    conn = @subject.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 422
    assert Poison.decode!(conn.resp_body, keys: :atoms) == %{active: "could not parse not-a-boolean as boolean"}
  end
end
