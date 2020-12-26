defmodule Chat.Channels.User.Message do
  # TODO: (Performance) Send notification to pid and let pid deliver messages to itself
  def deliver_pending_messages(%Chat.User{} = receipient, pid) do
    Chat.Message.get_messages(receipient.username, receipient.last_online)
    |> Enum.each(
      &send(pid, %{
        "event" => "user:message_reply",
        "message" => Map.merge(&1, %{name: &1.sender.name})
      })
    )
  end

  def deliver_pending_messages(%Chat.User{} = receipient, %Chat.User{} = sender, pid) do
    messages =
      Chat.Message.get_messages(receipient.username, sender.username, receipient.last_online)

    Enum.each(
      messages,
      &send(pid, %{
        "event" => "user:message_reply",
        "message" => Map.merge(&1, %{name: sender.name})
      })
    )
  end

  defmacro __using__([]) do
    quote do
      import Ecto.Query

      defp send_message(message, %{"users" => users} = state) do
        user = Enum.find(users, &(&1.user.username == message.receipient_id))

        if user != nil do
          # If connection is nil that means we were connected to the user
          # but the connection is lost now. The message will be delivered
          # when the user reconnects
          if user.connection != nil do
            send(user.connection, %{"event" => "user:message_reply", "message" => message})
          end

          state
        else
          # initate connection if user is not connected
          {:ok, state} =
            websocket_handle(
              {:json, %{"event" => "user:connecting", "username" => message.receipient_id}},
              state
            )

          state
        end
      end

      def websocket_handle(
            {:json, %{"event" => "group:message_send", "group" => id, "message" => message}},
            %{"user" => sender} = state
          ) do
        Chat.UserGroup.message(id, message, sender)
        {:ok, state}
      end

      def websocket_handle(
            {:json,
             %{"event" => "user:message_send", "receipient" => name, "message" => message}},
            %{"users" => users, "user" => sender} = state
          ) do
        contact = Chat.UserConversations.get_contact(sender.username, name)

        contact =
          if contact == nil do
            contact =
              Chat.UserConversations.changeset(%Chat.UserConversations{}, %{
                "from_id" => sender.username,
                "to_id" => name
              })

            Chat.Repo.insert!(contact)
          else
            contact
          end

        if contact.blocked != 1 do
          changeset =
            Chat.Message.changeset(%Chat.Message{}, %{
              "sender_id" => sender.username,
              "receipient_id" => name,
              "message" => message
            })

          message = Chat.Repo.insert!(changeset)

          state =
            send_message(
              Map.merge(message, %{
                name: sender.name
              }),
              state
            )

          {:reply, {:text, Poison.encode!(%{"status" => 200})}, state}
        else
          message =
            %{
              "message" => "You are not allowed to send message to #{name}",
              "sender" => name,
              "timestamp" => DateTime.utc_now(),
              "event" => "user:message_reply",
              "group" => nil,
              "blocked" => true
            }
            |> Poison.encode!()

          {:reply, {:text, message}, state}
        end
      end

      def websocket_info(
            %{"event" => "group:message_reply"} = payload,
            %{"user" => receipient} = state
          ) do
        {:reply, {:text, Poison.encode!(payload)}, state}
      end

      def websocket_info(%{"event" => "user:message_reply", "message" => message}, state) do
        reply = %{
          "message" => message.message,
          "sender" => message.sender_id,
          "name" => message.name,
          "timestamp" =>
            DateTime.diff(message.inserted_at, ~U[1970-01-01 00:00:00.0Z], :millisecond),
          "event" => "user:message_reply"
        }

        {:reply, {:text, Poison.encode!(reply)}, state}
      end
    end
  end
end
