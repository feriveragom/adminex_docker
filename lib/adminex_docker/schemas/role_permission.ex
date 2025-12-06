defmodule AdminexDocker.Schemas.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  schema "role_permissions" do
    field :role_id, :binary_id, primary_key: true
    field :permission_id, :binary_id, primary_key: true
    
    belongs_to :role, AdminexDocker.Schemas.Role, define_field: false
    belongs_to :permission, AdminexDocker.Schemas.Permission, define_field: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role_id, :permission_id])
    |> validate_required([:role_id, :permission_id])
    |> unique_constraint([:role_id, :permission_id])
  end
end
