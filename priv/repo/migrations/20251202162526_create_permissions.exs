defmodule AdminexDocker.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string, null: false  # e.g., "user.create", "role.delete"
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:code])
  end
end
