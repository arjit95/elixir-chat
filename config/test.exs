import Config

config :chat, Chat.Repo,
  db_url: "ecto://root:root@127.0.0.1:6603/chat",
  adapter: Ecto.Adapters.MyXQL,
  pool_size: 2

config :chat,
  port: "4002",
  load_from_system_env: true,
  env: :dev

config :joken,
  default_signer: "secret"

config :logger,
  level: "warn"
