defmodule Chat.UserConversations do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @primary_key false
  schema "user_conversations" do
    belongs_to(:from, Chat.User, foreign_key: :from_id, references: :username, define_field: false)

    belongs_to(:to, Chat.User, foreign_key: :to_id, references: :username, define_field: false)

    field(:from_id, :string, primary_key: true)
    field(:to_id, :string, primary_key: true)
    field(:blocked, :integer, size: 1)
    timestamps()
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:from_id, :to_id])
    |> validate_required([:from_id, :to_id])
    |> unique_constraint([:from_id, :to_id])
  end

  def get_contact(from, to) do
    query =
      from(u in Chat.UserConversations,
        where: u.from_id == ^from and u.to_id == ^to
      )

    Chat.Repo.one(query)
  end

  def get_contacts(from) do
    query =
      from(u in Chat.UserConversations,
        where: u.from_id == type(^from, :string),
        preload: [:to]
      )

    Chat.Repo.all(query)
  end

  @spec block(binary(), binary()) ::
          {:ok, %Chat.UserConversations{}} | {:error, Ecto.Changeset.t()}
  def block(from, to) do
    get_contact(from, to)
    |> Ecto.Changeset.change(blocked: 1)
    |> Chat.Repo.update()
  end

  def get_mutual_contacts(from) do
    query =
      from(u in Chat.UserConversations,
        where: u.to_id == type(^from, :string) and u.blocked != 1,
        preload: [:from]
      )

    Chat.Repo.all(query)
  end
end
