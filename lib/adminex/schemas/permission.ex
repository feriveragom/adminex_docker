defmodule Adminex.Schemas.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "permissions" do
    field :code, :string
    field :description, :string

    many_to_many :roles, Adminex.Schemas.Role, join_through: "role_permissions"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:code, :description])
    |> validate_required([:code])
    |> unique_constraint(:code)
  end

  # Constantes de permisos
  @admin_access "admin.access"
  @users_read "users.read"
  @users_write "users.write"
  @roles_read "roles.read"
  @roles_write "roles.write"

  def admin_access, do: @admin_access
  def users_read, do: @users_read
  def users_write, do: @users_write
  def roles_read, do: @roles_read
  def roles_write, do: @roles_write
end
