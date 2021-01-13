defmodule Chat.UserController do
  def create(params) do
    changeset = Chat.User.changeset(%Chat.User{}, params)

    case Chat.Repo.insert(changeset) do
      {:ok, _} -> %{"status" => 200, "data" => %{"message" => "Successfully registered"}}
      {:error, _} -> %{"status" => 500, "data" => %{"error" => "Cannot create user"}}
    end
  end

  defp gen_token_from_refresh(%Plug.Conn{} = conn) do
    refresh = Map.get(Plug.Conn.fetch_cookies(conn).req_cookies, "refresh_token", nil)

    if is_nil(refresh) do
      {nil, nil, nil}
    else
      case Chat.RefreshToken.verify_and_validate(refresh) do
        {:ok, claims} -> {Plug.Auth.gen_user_token(claims), refresh, claims}
        {:error, _} -> {nil, nil, nil}
      end
    end
  end

  def refresh_token(%Plug.Conn{} = conn) do
    %{"token" => token} = conn.params
    refresh = Map.get(Plug.Conn.fetch_cookies(conn).req_cookies, "refresh_token", nil)

    {token, refresh, user} =
      if is_nil(token) do
        gen_token_from_refresh(conn)
      else
        case Chat.Token.verify_and_validate(token) do
          {:ok, claims} -> {Plug.Auth.gen_user_token(claims), refresh, claims}
          {:error, _} -> gen_token_from_refresh(conn)
        end
      end

    if token == nil or refresh == nil do
      %{"status" => 401, "data" => %{"error" => "Session expired please login again."}}
    else
      user = Chat.Repo.get!(Chat.User, Map.get(user, "username"))

      %{
        "status" => 200,
        "data" => %{
          "token" => token,
          "expiry" => Chat.Token.expiry() * 1000,
          "username" => user.username,
          "name" => user.name
        }
      }
    end
  end

  def search(%{"query" => query, "username" => username}) do
    results =
      Chat.User.search(username, query)
      |> Enum.map(&%{"username" => Enum.at(&1, 0), "name" => Enum.at(&1, 1)})

    %{"status" => 200, "data" => %{"results" => results}}
  end

  def login!(%{"username" => username, "password" => password}) do
    user = Chat.User.verify_user!(username, password)
    {token, refresh_token} = Plug.Auth.gen_tokens(%{"username" => user.username})

    %{
      "status" => 200,
      "data" => %{
        "message" => "Successfully logged in",
        "token" => token,
        "expiry" => Chat.Token.expiry() * 1000,
        "username" => user.username,
        "name" => user.name
      },
      "cookies" => %{
        "refresh_token" => %{
          "data" => refresh_token,
          "options" => [
            max_age: 7 * 24 * 60 * 60,
            http_only: true,
            same_site: "Strict",
            secure: Mix.env() == :prod
          ]
        }
      }
    }
  end

  def get_contacts(%{"username" => username}) do
    contacts =
      Chat.UserConversations.get_contacts(username)
      |> Enum.map(&%{"username" => &1.to_id, "name" => &1.to.name})

    %{"status" => 200, "data" => %{"contacts" => contacts}}
  end

  def get_mutual_contacts(%{"username" => username}) do
    contacts =
      Chat.UserConversations.get_mutual_contacts(username)
      |> Enum.map(&%{"username" => &1.from_id, "name" => &1.from.name})

    %{"status" => 200, "data" => %{"contacts" => contacts}}
  end

  def get_memberships(%{"username" => username}) do
    %{"status" => 200, "data" => %{"memberships" => Chat.GroupMember.get_memberships(username)}}
  end

  def block(%{"username" => username, "receipient" => receipient}) do
    # Block communications from receipient
    Chat.UserConversations.block(receipient, username)
    %{"status" => 200, "data" => %{"message" => "User blocked successfully"}}
  end
end
