defmodule Plug.Validator do
  alias Plug.Conn
  def init(opts), do: opts
  def call(conn, opts) do
    case conn.private[:validate] do
      nil -> conn
      validations -> validate(Conn.fetch_query_params(conn), validations, opts[:on_error])
    end
  end

  defp validate(conn, validations, on_error) do
    errors = collect_errors(conn, validations)
    if Enum.empty? errors do
      conn
    else
      on_error.(conn, errors)
    end
  end

  defp collect_errors(conn, validations) do
    Enum.reduce(validations, %{}, errors_collector(conn))
  end

  defp errors_collector(conn) do
    fn {field, vf}, acc -> 
      value = conn.params[Atom.to_string(field)]
      case vf.(value) do
        {:error, msg} -> Map.put(acc, field, msg)
        _ -> acc
      end
    end
  end

end
