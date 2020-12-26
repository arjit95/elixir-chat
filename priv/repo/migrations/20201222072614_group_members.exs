defmodule Chat.Repo.Migrations.GroupMembers do
  use Ecto.Migration

  def change do
    create table(:group_members, primary_key: false) do
      add :user_id, references(:users, type: :string, null: false, column: :username, on_delete: :delete_all), primary_key: true
      add :group_id, references(:groups, type: :string, null: false, column: :id, on_delete: :delete_all), primary_key: true
      add :role, :integer, default: 1
      timestamps()
    end

    create unique_index(:group_members, [:user_id, :group_id])
  end
end
