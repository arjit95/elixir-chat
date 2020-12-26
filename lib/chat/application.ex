defmodule Chat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = [
      chat: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    # List all child processes to be supervised
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Chat.Endpoint,
        dispatch: dispatch(),
        options: [
          port: String.to_integer(Application.fetch_env!(:chat, :port)),
          ip: {0, 0, 0, 0}
        ]
      ),
      {Cluster.Supervisor, [topologies, [name: Chat.ClusterSupervisor]]},
      Chat.GroupSuperVisor,
      {
        Phoenix.PubSub,
        adapter: Phoenix.PubSub.PG2, name: :chat
      },
      Chat.Repo
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    IO.puts("Server running on port " <> Application.fetch_env!(:chat, :port))
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws", Chat.Channels.User.Socket, []},
         {:_, Plug.Cowboy.Handler, {Chat.Endpoint, []}}
       ]}
    ]
  end
end
