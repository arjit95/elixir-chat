defmodule Chat.Channels.User.Monitor do
  defmacro __using__([]) do
    quote do
      def websocket_info({:disconnect, username}, %{"users" => users} = state) do
        if Map.get(state, "authenticated") do
          users = Enum.reject(users, &(&1.user.username == username))
          {:ok, %{state | "users" => users}}
        else
          {:ok, state}
        end
      end

      def terminate(
            _reason,
            _req,
            %{"user" => user, "users" => users, "groups" => groups} = state
          ) do
        if Map.get(state, "authenticated", nil) do
          Phoenix.PubSub.unsubscribe(:chat, user.username)

          users =
            Enum.map(users, & &1.connection)
            |> Enum.filter(&(&1 != nil))

          Manifold.send(users, {:disconnect, user.username})

          groups
          |> Enum.each(&Chat.UserGroup.disconnect/1)

          Chat.Repo.update(Ecto.Changeset.change(user, last_online: DateTime.utc_now()))
          IO.puts("User session terminated #{user.username}")
        end

        :ok
      end
    end
  end
end
