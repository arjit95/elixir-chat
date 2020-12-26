import Config

config :chat, Chat.Repo,
  database: "chat",
  username: "root",
  password: "root",
  hostname: "127.0.0.1",
  port: 6603,
  adapter: Ecto.Adapters.MyXQL,
  pool_size: 2

config :chat,
  port: "4000"

config :joken,
  default_signer: "secret"

config :logger,
  level: :info
