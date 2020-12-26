defmodule Chat.Channels.User.RTC do
  def can_send_message(from, to, users) do
    contact = Chat.UserConversations.get_contact(from, to)
    receipient = Enum.find(users, &(&1.user.username == to))

    message =
      cond do
        contact == nil or contact.blocked == 1 ->
          %{
            "error" => "You are not allowed to send file to #{to}",
            "timestamp" => DateTime.utc_now()
          }

        receipient == nil or receipient.connection == nil ->
          %{
            "error" => "#{to} is not online",
            "timestamp" => DateTime.utc_now()
          }

        true ->
          nil
      end

    {message, receipient}
  end

  defmacro __using__([]) do
    quote do
      def websocket_handle(
            {
              :json,
              %{"event" => "user:rtc_offer", "offer" => offer, "receipient" => name} = params
            },
            %{"users" => users, "user" => sender} = state
          ) do
        {message, receipient} =
          Chat.Channels.User.RTC.can_send_message(sender.username, name, users)

        if message != nil do
          message =
            message
            |> Map.merge(%{"event" => "user:rtc_offer", "sender" => name})
            |> Poison.encode!()

          {:reply, {:text, message}, state}
        else
          send(receipient.connection, Map.merge(%{"sender" => sender.username}, params))
          {:ok, state}
        end
      end

      def websocket_handle(
            {
              :json,
              %{"event" => "user:rtc_answer", "answer" => answer, "receipient" => name} = params
            },
            %{"users" => users, "user" => sender} = state
          ) do
        receipient = Enum.find(users, &(&1.user.username == name))

        if receipient == nil or receipient.connection == nil do
          message = %{
            "error" => "#{name} is not online",
            "timestamp" => DateTime.utc_now(),
            "event" => "user:rtc_answer",
            "sender" => name
          }

          {:reply, {:text, Poison.encode!(message)}, state}
        else
          send(receipient.connection, Map.merge(%{"sender" => sender.username}, params))
          {:ok, state}
        end
      end

      def websocket_info(%{"event" => "user:rtc_offer"} = payload, state) do
        {:reply, {:text, Poison.encode!(payload)}, state}
      end

      def websocket_info(%{"event" => "user:rtc_answer"} = payload, state) do
        {:reply, {:text, Poison.encode!(payload)}, state}
      end
    end
  end
end
