defmodule Chat.Channels.User.Auth do
  defmacro __using__([]) do
    quote do
      # authenticate the user and subscribe to a room with same name as username
      # this allows us to send any broadcast to that room to inform the user about
      # any updates
      def websocket_handle(
            {:json, %{"event" => "authenticate", "username" => user} = params},
            state
          ) do
        Phoenix.PubSub.subscribe(:chat, user)

        info = Chat.Repo.get!(Chat.User, user)
        pid = self()
        memberships = Chat.GroupMember.get_memberships(user)

        Task.start(fn ->
          :timer.sleep(2000)
          Enum.each(memberships, &Chat.UserGroup.connect(pid, &1))
          Chat.Channels.User.Message.deliver_pending_messages(info, pid)
        end)

        state = %{state | "groups" => memberships}
        reply = Map.merge(params, %{"name" => info.name})

        {:reply, {:text, Poison.encode!(reply)},
         Map.merge(state, %{
           "user" => %Chat.User{info | last_online: DateTime.utc_now()},
           "authenticated" => true
         })}
      end
    end
  end
end
