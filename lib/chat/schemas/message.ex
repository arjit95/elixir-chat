defmodule Chat.Message do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @primary_key false
  schema "messages" do
    field(:message, :string)

    belongs_to(:sender, Chat.User,
      foreign_key: :sender_id,
      references: :username,
      define_field: false
    )

    belongs_to(:receipient, Chat.User,
      foreign_key: :receipient_id,
      references: :username,
      define_field: false
    )

    field(:sender_id, :string, primary_key: true)
    field(:receipient_id, :string, primary_key: true)
    field(:inserted_at, :utc_datetime_usec, primary_key: true)
    field(:updated_at, :utc_datetime_usec)
  end

  def changeset(data, params \\ %{}) do
    timestamp = DateTime.utc_now()

    data
    |> cast(params, [:sender_id, :receipient_id, :message, :inserted_at, :updated_at])
    |> put_change(:inserted_at, timestamp)
    |> put_change(:updated_at, timestamp)
    |> validate_required([:sender_id, :receipient_id, :message])
    |> unique_constraint([:sender_id, :receipient_id, :inserted_at])
  end

  def get_messages(receipient, from_time) do
    query =
      from(m in Chat.Message,
        where: m.receipient_id == type(^receipient, :string) and m.inserted_at > ^from_time,
        order_by: [asc: :inserted_at],
        preload: [:sender]
      )

    Chat.Repo.all(query)
  end

  def get_messages(receipient, sender, from_time) do
    query =
      from(m in Chat.Message,
        where:
          m.receipient_id == type(^receipient, :string) and m.sender_id == type(^sender, :string) and
            m.inserted_at > ^from_time,
        order_by: [asc: :inserted_at]
      )

    Chat.Repo.all(query)
  end
end
