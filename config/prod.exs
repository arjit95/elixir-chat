import Config

db_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :chat, Chat.Repo,
  url: db_url,
  adapter: Ecto.Adapters.Postgres,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2")

config :chat,
  port: System.get_env("PORT") || "443",
  load_from_system_env: true

config :joken,
  default_signer: System.get_env("SIGNING_KEY")

config :logger,
  level: :info
