defmodule Chat.Repo.Migrations.CreateGroupMessages do
  use Ecto.Migration

  def change do
    create table(:group_messages, primary_key: false) do
      add :sender_id, references(:users, type: :string, null: false, column: :username, on_delete: :delete_all), primary_key: true
      add :group_id, references(:groups, type: :string, null: false, column: :id, on_delete: :delete_all), primary_key: true
      add :message, :text

      add :inserted_at, :utc_datetime_usec, primary_key: true
      add :updated_at, :utc_datetime_usec
    end

    create index(:group_messages, [:group_id])
  end
end
