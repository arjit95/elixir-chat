defmodule Chat.Repo do
  use Ecto.Repo,
      [otp_app: :chat] ++ Application.fetch_env!(:chat, __MODULE__)
end
