defmodule Chat.Channels.User.Groups do
  defmacro __using__([]) do
    quote do
      def websocket_info(
            %{"event" => "group:join", "membership" => membership},
            %{"groups" => groups} = state
          ) do
        idx = Enum.find_index(groups, &(&1.group_id == membership.group_id))

        if idx == nil do
          Chat.UserGroup.connect(self(), membership)
          groups = [membership | groups]

          reply = %{
            "event" => "group:join",
            "group" => Chat.Repo.get!(Chat.Group, membership.group_id)
          }

          {:reply, {:text, Poison.encode!(reply)}, %{state | "groups" => groups}}
        else
          {:ok, state}
        end
      end

      def websocket_info(%{"event" => "group:member_join", "membership" => membership}, state) do
        user = Chat.Repo.get!(Chat.User, membership.user_id)

        reply = %{
          "event" => "group:member_join",
          "group_id" => membership.group_id,
          "user_id" => user.username,
          "user" => %{
            "username" => user.username,
            "name" => user.name
          }
        }

        {:reply, {:text, Poison.encode!(reply)}, state}
      end

      def websocket_info(
            %{"event" => "group:member_leave", "membership" => membership},
            %{"user" => info, "groups" => groups} = state
          ) do
        user =
          if info.username == membership.user_id,
            do: info,
            else: Chat.Repo.get!(Chat.User, membership.user_id)

        state =
          if info.username == membership.user_id do
            idx = Enum.find_index(groups, &(membership.group_id == &1.group_id))
            groups = if idx != nil, do: List.delete_at(groups, idx), else: groups
            %{state | "groups" => groups}
          else
            state
          end

        reply = %{
          "event" => "group:member_leave",
          "group_id" => membership.group_id,
          "user_id" => user.username,
          "user" => %{
            "username" => user.username,
            "name" => user.name
          }
        }

        {:reply, {:text, Poison.encode!(reply)}, state}
      end
    end
  end
end
