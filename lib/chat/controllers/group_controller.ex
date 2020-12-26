defmodule Chat.GroupController do
  def create!(%{"group" => name, "username" => username} = params) do
    group = Chat.Group.create!(name, username)
    Chat.GroupSuperVisor.create(group)

    Map.get(params, "members", [])
    |> Enum.each(&join!(%{"group" => group.id, "username" => &1}))

    %{"status" => 200, "data" => %{"group" => group}}
  end

  def remove(%{"group" => id, "username" => _username}) do
    Chat.Group.delete(id)
    %{"status" => 200, "data" => %{"message" => "Group Deleted successfully"}}
  end

  def join!(%{"payload" => payload}) do
    Enum.each(payload, &join!/1)
    %{"status" => 200, "data" => %{"message" => "Your request will soon be completed."}}
  end

  def join!(%{"group" => id, "username" => username}) do
    group = Chat.Repo.get!(Chat.Group, id)
    user = Chat.Repo.get!(Chat.User, username)
    {:ok, membership} = Chat.GroupMember.add_membership(user, group)
    Chat.UserGroup.add(membership)
    %{"status" => 200, "data" => %{"message" => "Your request will soon be completed."}}
  end

  def members(%{"group" => id, "username" => username}) do
    if !Chat.GroupMember.has_membership?(id, username) do
      %{"status" => 401, "data" => %{"error" => "Not Authorized"}}
    else
      %{
        "status" => 200,
        "data" => %{
          "members" => Chat.GroupMember.get_all_members(id),
          "group" => Chat.Repo.get!(Chat.Group, id)
        }
      }
    end
  end

  def info(%{"group" => id} = params) do
    info = members(params)

    info =
      if Map.has_key?(info, "error"),
        do: info,
        else: Map.merge(info, Chat.Repo.get(Chat.Group, id))

    %{"status" => 200, "data" => info}
  end

  def kick(%{"payload" => payload}) do
    Enum.each(payload, &kick/1)
    %{"status" => 200, "data" => %{"message" => "Successfully kicked user"}}
  end

  def kick(%{"group" => id, "username" => username}) do
    Chat.GroupMember.remove_membership(id, username)
    |> Chat.UserGroup.remove()

    %{"status" => 200, "data" => %{"message" => "Successfully kicked user"}}
  end
end
