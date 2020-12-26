defmodule Chat.GroupSuperVisor do
  use DynamicSupervisor

  def start_link(arg),
    do: DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)

  def init(_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one)

  def create(group),
    do: DynamicSupervisor.start_child(__MODULE__, {Chat.UserGroup, group})
end
