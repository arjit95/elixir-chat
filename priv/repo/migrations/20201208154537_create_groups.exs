defmodule Chat.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups, primary_key: false) do
      add :id, :string, primary_key: true
      add :admin_id, references(:users, type: :string, null: false, column: :username, on_delete: :delete_all)
      add :name, :string

      timestamps(type: :utc_datetime_usec)
    end
  end
end
