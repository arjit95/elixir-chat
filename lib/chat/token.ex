defmodule Chat.Token do
  use Joken.Config

  def token_config, do: default_claims(default_exp: expiry())

  # 15 mins
  def expiry, do: 15 * 60
end

defmodule Chat.RefreshToken do
  use Joken.Config

  def token_config, do: default_claims(default_exp: expiry())

  # 1 week
  def expiry, do: 7 * 24 * 60 * 60
end
