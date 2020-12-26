defmodule Chat.GroupMessages do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @primary_key false
  schema "group_messages" do
    belongs_to(:sender, Chat.User,
      foreign_key: :sender_id,
      references: :username,
      define_field: false
    )

    belongs_to(:group, Chat.Group, foreign_key: :group_id, references: :id, define_field: false)

    field(:message, :string)
    field(:sender_id, :string, primary_key: true)
    field(:group_id, :string, primary_key: true)
    field(:inserted_at, :utc_datetime_usec, primary_key: true)
    field(:updated_at, :utc_datetime_usec)
  end

  def changeset(data, params \\ %{}) do
    timestamp = DateTime.utc_now()

    data
    |> cast(params, [:sender_id, :message, :group_id, :inserted_at, :updated_at])
    |> put_change(:inserted_at, timestamp)
    |> put_change(:updated_at, timestamp)
    |> validate_required([:sender_id, :group_id, :message])
    |> unique_constraint([:sender_id, :group_id, :inserted_at])
  end

  def get_messages(group_id, username, from_time) do
    query =
      from(m in Chat.GroupMessages,
        where:
          m.group_id == type(^group_id, :string) and m.inserted_at > ^from_time and
            m.sender_id != type(^username, :string),
        order_by: [asc: :inserted_at]
      )

    Chat.Repo.all(query)
  end
end
