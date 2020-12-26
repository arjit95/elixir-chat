defmodule Chat.Group do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  schema "groups" do
    belongs_to(:admin, Chat.User,
      foreign_key: :admin_id,
      references: :username,
      define_field: false
    )

    field(:admin_id, :string)
    field(:name, :string)
    field(:id, :string, primary_key: true)

    timestamps()
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:id, :admin_id, :name])
    |> unique_constraint([:id])
  end

  @spec create!(binary(), binary()) :: %Chat.Group{}
  def create!(group_name, username) do
    group_id = Nanoid.generate()

    changeset =
      Chat.Group.changeset(%Chat.Group{}, %{
        "admin_id" => username,
        "id" => group_id,
        "name" => group_name
      })

    group = Chat.Repo.insert!(changeset)
    user = Chat.Repo.get!(Chat.User, username)
    Chat.GroupMember.add_membership(user, group, true)

    group
  end

  def delete(group_id) do
    Chat.Repo.get!(Chat.Group, group_id)
    |> Chat.Repo.delete()
  end
end
