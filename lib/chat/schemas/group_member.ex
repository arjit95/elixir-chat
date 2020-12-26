defmodule Chat.GroupMember do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  @primary_key false
  schema "group_members" do
    belongs_to(:user, Chat.User, foreign_key: :user_id, references: :username, define_field: false)

    belongs_to(:group, Chat.Group, foreign_key: :group_id, references: :id, define_field: false)
    field(:user_id, :string, primary_key: true)
    field(:group_id, :string, primary_key: true)

    field(:role, :integer)
    timestamps()
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:user_id, :group_id])
    |> unique_constraint([:user_id, :group_id])
  end

  @spec add_membership(%Chat.User{}, %Chat.Group{}, boolean()) ::
          {:ok, %Chat.GroupMember{}} | {:error, list(String.t())}
  def add_membership(%Chat.User{} = user, %Chat.Group{} = group, admin \\ false) do
    role = if admin == true, do: 0, else: 1

    change =
      changeset(%Chat.GroupMember{}, %{
        "group_id" => group.id,
        "role" => role,
        "user_id" => user.username
      })

    case Chat.Repo.insert(change) do
      {:ok, struct} -> {:ok, struct}
      {:error, change} -> {:error, change.errors}
    end
  end

  @spec remove_all_memberships(String.t()) :: term()
  def remove_all_memberships(group_id) do
    query =
      from(g in Chat.GroupMember,
        where: g.group_id == ^group_id
      )

    Chat.Repo.delete_all(query)
  end

  def remove_membership(group_id, username) do
    # query = from g in Chat.GroupMember,
    #   where: g.group_id == ^group_id and g.user_id == ^username,
    #   limit: 1

    Chat.Repo.get_by!(Chat.GroupMember, user_id: username, group_id: group_id)
    |> Chat.Repo.delete!()
  end

  @spec get_all_members(String.t()) :: list(%Chat.GroupMember{})
  def get_all_members(group_id) do
    query =
      from(g in Chat.GroupMember,
        where: g.group_id == ^group_id,
        left_join: user in assoc(g, :user),
        select: %{
          group_id: g.group_id,
          user_id: g.user_id,
          user: %{username: user.username, name: user.name}
        }
      )

    Chat.Repo.all(query)
  end

  @spec has_membership?(String.t(), String.t()) :: boolean()
  def has_membership?(group_id, username) do
    query =
      from(g in Chat.GroupMember,
        where: g.group_id == type(^group_id, :string) and g.user_id == type(^username, :string),
        limit: 1
      )

    length(Chat.Repo.all(query)) > 0
  end

  @spec get_memberships(String.t()) :: list(%Chat.GroupMember{})
  def get_memberships(username) do
    query =
      from(gm in Chat.GroupMember,
        where: gm.user_id == type(^username, :string),
        preload: [:group]
      )

    Chat.Repo.all(query)
  end
end
