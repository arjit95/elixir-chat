defmodule Chat.Channels.User.Connections do
  alias Chat.Models.User

  defmacro __using__([]) do
    quote do
      # the user will initiate an event requesting connection to the remote user
      def websocket_handle(
            {:json, %{"event" => "user:connecting", "username" => receipient}},
            %{"users" => users} = state
          ) do
        sender = Map.get(state, "user")
        receipient = Chat.Repo.get!(Chat.User, receipient)

        Phoenix.PubSub.broadcast(:chat, receipient.username, %{
          "event" => "user:connecting",
          "user" => sender,
          "socket" => self()
        })

        {:ok, %{state | "users" => [%User{user: receipient}] ++ users}}
      end

      # connection request will be received and a response will be sent if the request
      # is acknowledged
      def websocket_info(
            %{"event" => "user:connecting", "user" => sender, "socket" => socket},
            %{"users" => users} = state
          ) do
        receipient = Map.get(state, "user")
        user = %User{user: sender, connection: socket}

        send(socket, %{"event" => "user:connected", "user" => receipient, "socket" => self()})
        {:ok, %{state | "users" => [user] ++ users}}
      end

      # the handshake is now completed, and both sides should be connected now.
      def websocket_info(
            %{"event" => "user:connected", "user" => receipient, "socket" => socket},
            %{"users" => users, "user" => sender} = state
          ) do
        user_idx = Enum.find_index(users, &(&1.user.username == receipient.username))

        if user_idx != nil do
          user = Enum.at(users, user_idx)
          users = List.update_at(users, user_idx, &%User{&1 | connection: socket})
          state = %{state | "users" => users}
          Chat.Channels.User.Message.deliver_pending_messages(receipient, sender, socket)

          {:reply, {:text, Poison.encode!(%{"status" => 200, "event" => "user:connected"})},
           state}
        else
          {:reply, {:text, Poison.encode!(%{"status" => 500, "event" => "user:connected"})},
           state}
        end
      end
    end
  end
end
