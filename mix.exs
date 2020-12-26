defmodule Chat.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Chat.Application, []},
      extra_applications: [:logger, :syn]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:plug_cowboy, "~> 2.4.1"},
      {:syn, "2.1.1"},
      {:manifold, "~> 1.0"},
      {:libcluster, "~> 3.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto_sql, "~> 3.0"},
      {:myxql, "~> 0.4.0"},
      {:nanoid, "~> 2.0.4"},
      {:joken, "~> 2.0"},
      {:argon2_elixir, "~> 2.0"},
      {:distillery, "~> 2.1.1", runtime: false},
      {:postgrex, "~> 0.15.7", only: [:prod]}
    ]
  end

  defp aliases() do
    [
      setup: ["deps.get --only dev", "ecto.setup", "cmd npm install --prefix web"],
      "ecto.setup": ["ecto.create", "ecto.migrate"]
    ]
  end
end
