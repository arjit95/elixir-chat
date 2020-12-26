defmodule Plug.Auth do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def gen_tokens(%{"username" => _username} = claims) do
    {gen_user_token(claims), gen_refresh_token(claims)}
  end

  def gen_user_token(%{"username" => _username} = claims) do
    Chat.Token.generate_and_sign!(claims)
  end

  def gen_refresh_token(%{"username" => _username} = claims) do
    Chat.RefreshToken.generate_and_sign!(claims)
  end

  defp authenticate(conn) do
    token = Map.get(conn.params, "token")

    case Chat.Token.verify_and_validate(token) do
      {:ok, claims} -> Map.merge(conn.params, claims)
      {:error, _} -> send_401(conn, %{message: "User does not exist"})
    end
  end

  defp send_401(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Poison.encode!(data))
    |> halt
  end

  def call(%Plug.Conn{path_info: path} = conn, _opts) do
    if Enum.at(path, 0) != "api" or Enum.at(path, 1) == "auth" do
      conn
    else
      conn
      |> authenticate
    end
  end
end
