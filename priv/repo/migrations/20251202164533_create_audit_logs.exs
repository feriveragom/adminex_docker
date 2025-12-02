defmodule Adminex.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string, null: false  # e.g., "user.created", "role.deleted"
      add :resource_type, :string         # e.g., "user", "role"
      add :resource_id, :string           # ID del recurso afectado
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :metadata, :map, default: %{}   # JSON con detalles adicionales
      add :ip_address, :string
      add :user_agent, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:audit_logs, [:action])
    create index(:audit_logs, [:resource_type, :resource_id])
    create index(:audit_logs, [:actor_id])
    create index(:audit_logs, [:inserted_at])
  end
end
