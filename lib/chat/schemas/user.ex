defmodule Unauthorized do
  defexception message: "Unauthorized", plug_status: 401
end

defmodule Chat.User do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:username, :string, autogenerate: false}
  schema "users" do
    field(:password, :string)
    field(:email, :string)
    field(:name, :string)
    field(:description, :string)
    field(:last_online, :utc_datetime_usec, default: DateTime.utc_now())
    timestamps()
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:username, :password, :email, :name, :description, :last_online])
    |> validate_required([:username, :password, :email, :name])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint([:username, :email])
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    %{password_hash: password} = Argon2.add_hash(password)
    change(changeset, password: password)
  end

  @spec verify_user!(String.t(), String.t()) :: nil | %__MODULE__{}
  def verify_user!(username, password) do
    user = Chat.Repo.get!(__MODULE__, username)

    case Argon2.check_pass(user, password, hash_key: :password) do
      {:ok, _} -> user
      {:error, _} -> raise Unauthorized
    end
  end

  def search(username, query, skip \\ 0, take \\ 10) do
    q0 =
      from(uc in Chat.UserConversations,
        where: uc.from_id == ^username or uc.to_id == ^username,
        select: uc.to_id
      )

    q =
      from(u in Chat.User,
        where: like(u.username, ^"%#{query}%") or like(u.name, ^"%#{query}%"),
        where: u.username not in subquery(q0) and u.username != ^username,
        select: [u.username, u.name],
        offset: ^skip,
        limit: ^take
      )

    Chat.Repo.all(q)
  end
end
