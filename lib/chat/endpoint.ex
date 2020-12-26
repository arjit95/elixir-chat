defmodule Chat.Endpoint do
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Logger)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :chat
  )

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)
  plug(Plug.Auth)
  plug(Plug.MethodOverride)
  plug(Plug.Head)

  def put_cookie(conn, key, val) do
    data = Map.get(val, "data")
    options = Map.get(val, "options", [])

    Plug.Conn.put_resp_cookie(conn, key, data, options)
  end

  def json(conn, resp) do
    status = Map.get(resp, "status", 200)
    data = Map.get(resp, "data", %{})
    cookies = Map.get(resp, "cookies", %{})

    conn
    |> (fn x ->
          Enum.reduce(Map.keys(cookies), x, &put_cookie(&2, &1, Map.get(cookies, &1)))
        end).()
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(status, Poison.encode!(data))
    |> halt()
  end

  # responsible for matching routes
  post "/api/groups/create" do
    json(conn, Chat.GroupController.create!(conn.params))
  end

  post "/api/groups/remove" do
    json(conn, Chat.GroupController.remove(conn.params))
  end

  post "/api/groups/join" do
    json(conn, Chat.GroupController.join!(conn.params))
  end

  post "/api/groups/leave" do
    json(conn, Chat.GroupController.kick(conn.params))
  end

  post "/api/groups/members" do
    json(conn, Chat.GroupController.members(conn.params))
  end

  post "api/groups/info" do
    json(conn, Chat.GroupController.info(conn.params))
  end

  post "/api/auth/create" do
    json(conn, Chat.UserController.create(conn.params))
  end

  post "/api/auth/login" do
    json(conn, Chat.UserController.login!(conn.params))
  end

  post "/api/refresh_token" do
    json(conn, Chat.UserController.refresh_token(conn))
  end

  get "/api/auth/logout" do
    conn
    |> Plug.Conn.delete_resp_cookie("refresh_token", same_site: "Strict")
    |> json(%{"status" => 200})
  end

  post "/api/user/search" do
    json(conn, Chat.UserController.search(conn.params))
  end

  post "/api/user/block" do
    json(conn, Chat.UserController.block(conn.params))
  end

  post "/api/user/contacts/available" do
    json(conn, Chat.UserController.get_contacts(conn.params))
  end

  post "/api/user/contacts/mutual" do
    json(conn, Chat.UserController.get_mutual_contacts(conn.params))
  end

  post "/api/user/memberships" do
    json(conn, Chat.UserController.get_memberships(conn.params))
  end

  match _ do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Plug.Conn.send_file(200, Application.app_dir(:chat, "priv/static/index.html"))
  end
end
