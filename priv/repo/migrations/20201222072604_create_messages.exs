defmodule Chat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :sender_id, references(:users, type: :string, null: false, column: :username, on_delete: :delete_all), primary_key: true
      add :receipient_id, references(:users, type: :string, null: false, column: :username, on_delete: :delete_all), primary_key: true
      add :message, :text

      add :inserted_at, :utc_datetime_usec, primary_key: true
      add :updated_at, :utc_datetime_usec
    end

    create index(:messages, [:receipient_id])
  end
end
