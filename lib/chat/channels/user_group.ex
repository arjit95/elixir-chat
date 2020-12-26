defmodule Chat.UserGroup do
  use GenServer

  defp via_tuple(group_id) do
    {:via, :syn, group_id}
  end

  def start_link(%Chat.Group{} = group) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [group], name: via_tuple(group.id))
    GenServer.cast(pid, {:start})

    {:ok, pid}
  end

  @impl true
  def handle_call({:add, %Chat.GroupMember{} = member}, _from, %{"members" => members} = state) do
    Phoenix.PubSub.broadcast!(:chat, member.user_id, %{
      "event" => "group:join",
      "membership" => member
    })

    broadcast(members, %{
      "event" => "group:member_join",
      "membership" => member
    })

    {:reply, :ok, %{state | "members" => [%Chat.Models.User{user: member} | members]}}
  end

  @impl true
  def handle_call({:remove, %Chat.GroupMember{} = member}, _from, %{"members" => members} = state) do
    broadcast(members, %{
      "event" => "group:member_leave",
      "membership" => member
    })

    {:reply, :ok,
     %{state | "members" => Enum.reject(members, &(&1.user.user_id === member.user_id))}}
  end

  @impl true
  def handle_call(
        {:connect, socket, %Chat.GroupMember{} = member},
        _from,
        %{"members" => members, "info" => group} = state
      ) do
    idx = Enum.find_index(members, &(&1.user.user_id == member.user_id))

    members =
      if idx != nil,
        do: List.update_at(members, idx, &%Chat.Models.User{&1 | connection: socket}),
        else: members

    # Deliver pending message to the user
    user = Chat.Repo.get(Chat.User, member.user_id)

    Chat.GroupMessages.get_messages(group.id, user.username, user.last_online)
    |> Enum.each(fn entry ->
      send(socket, %{
        "event" => "group:message_reply",
        "message" => entry.message,
        "sender" => entry.sender_id,
        "name" => user.name,
        "group" => group.id,
        "timestamp" => entry.inserted_at
      })
    end)

    {:reply, :ok, %{state | "members" => members}}
  end

  @impl true
  def handle_call(
        {:disconnect, %Chat.GroupMember{} = member},
        _from,
        %{"members" => members} = state
      ) do
    idx = Enum.find_index(members, &(&1.user.user_id == member.user_id))

    members =
      if idx != nil,
        do: List.update_at(members, idx, &%Chat.Models.User{&1 | connection: nil}),
        else: members

    {:reply, :ok, %{state | "members" => members}}
  end

  @impl true
  def handle_call(
        {:message, message, sender},
        _from,
        %{"info" => group, "members" => members} = state
      ) do
    message = %{
      "event" => "group:message_reply",
      "message" => message,
      "sender" => sender.username,
      "group" => group.id,
      "timestamp" => DateTime.utc_now(),
      "name" => sender.name
    }

    send_message(group, members, message)
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:start}, %{"members" => members} = state) do
    Enum.each(
      members,
      &Phoenix.PubSub.broadcast!(:chat, &1.user.user_id, %{
        "event" => "group:join",
        "membership" => &1.user
      })
    )

    {:noreply, state}
  end

  @impl true
  def handle_cast({:delete}, %{"members" => members, "info" => group} = state) do
    ## delete all messages
    Chat.Group.delete(group.id)
    broadcast(members, %{"event" => "group:delete", "group" => group})
    {:stop, :normal, state}
  end

  @impl true
  def init([group]) do
    members =
      Chat.GroupMember.get_all_members(group.id)
      |> Enum.map(fn x -> %Chat.Models.User{user: x} end)

    {:ok, %{"info" => group, "members" => members}}
  end

  defp broadcast(members, info) do
    online_users =
      Enum.filter(members, fn member -> member.connection != nil end)
      |> Enum.map(& &1.connection)

    Manifold.send(online_users, info)
  end

  defp send_message(group, members, info) do
    sender = Map.get(info, "sender")

    message =
      Chat.GroupMessages.changeset(%Chat.GroupMessages{}, %{
        "sender_id" => sender,
        "group_id" => group.id,
        "message" => Map.get(info, "message")
      })

    broadcast(members, info)
    Chat.Repo.insert!(message)
  end

  @impl true
  def terminate(reason, %{"info" => group}) do
    if reason != :normal do
      Chat.GroupSuperVisor.create(group)
    end

    :ok
  end

  ## Starts the server if the app was restarted
  defp start_server(group_id) do
    if :syn.whereis(group_id) == :undefined do
      group = Chat.Repo.get!(Chat.Group, group_id)
      Chat.GroupSuperVisor.create(group)
    end
  end

  defp call(tup, args) do
    elem(tup, 2)
    |> start_server()

    GenServer.call(tup, args)
  end

  defp cast(tup, args) do
    elem(tup, 2)
    |> start_server()

    GenServer.cast(tup, args)
  end

  @spec message(String.t(), String.t(), String.t()) :: term()
  def message(group_id, message, sender) do
    call(via_tuple(group_id), {:message, message, sender})
  end

  @doc """
  Add a member to the server
  """
  @spec add(%Chat.GroupMember{}) :: term()
  def add(member) do
    call(via_tuple(member.group_id), {:add, member})
  end

  @doc """
  Remove a member to the server
  """
  @spec remove(%Chat.GroupMember{}) :: term()
  def remove(member) do
    call(via_tuple(member.group_id), {:remove, member})
  end

  @doc """
  Connect the member to the server once he is online
  """
  @spec connect(pid(), %Chat.GroupMember{}) :: term()
  def connect(socket, member) do
    call(via_tuple(member.group_id), {:connect, socket, member})
  end

  @doc """
  Disconnect the member to the server once he is online
  """
  @spec disconnect(%Chat.GroupMember{}) :: term()
  def disconnect(member) do
    call(via_tuple(member.group_id), {:disconnect, member})
  end

  @doc """
  Deletes the group and notifies all the members
  """
  @spec delete(%Chat.Group{}) :: term()
  def delete(group) do
    cast(via_tuple(group.id), {:delete})
  end

  def publish_info(group_id, info) do
    call(via_tuple(group_id), {:info, info})
  end
end
