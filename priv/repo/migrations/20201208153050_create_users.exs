defmodule Chat.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :username, :string, primary_key: true
      add :password, :string
      add :email, :string
      add :name, :string
      add :description, :string
      add :last_online, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:users, [:username])
  end
end
