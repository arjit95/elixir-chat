defmodule Chat.Repo.Migrations.UserConversation do
  use Ecto.Migration

  def change do
    create table(:user_conversations, primary_key: false) do
      add :from_id, references(:users, type: :string, null: false, column: :username, on_delete: :delete_all), primary_key: true
      add :to_id, references(:users, type: :string, null: false, column: :username, on_delete: :delete_all), primary_key: true
      add :blocked, :integer, default: 0
      timestamps()
    end

    create unique_index(:user_conversations, [:from_id, :to_id])
  end
end
