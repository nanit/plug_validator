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

