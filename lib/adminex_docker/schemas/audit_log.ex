defmodule AdminexDocker.Schemas.AuditLog do
  @moduledoc """
  Schema para los registros de auditoría del sistema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias AdminexDocker.Schemas.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :string
    field :metadata, :map, default: %{}
    field :ip_address, :string
    field :user_agent, :string

    belongs_to :actor, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @required_fields ~w(action)a
  @optional_fields ~w(resource_type resource_id metadata ip_address user_agent actor_id)a

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
