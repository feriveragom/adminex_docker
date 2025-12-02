defmodule Adminex.Schemas.Role do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "roles" do
    field :name, :string
    field :description, :string

    has_many :users, Adminex.Schemas.User
    many_to_many :permissions, Adminex.Schemas.Permission, join_through: "role_permissions"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  # Constantes de roles
  @super_admin "SUPER_ADMIN"
  @admin "ADMIN"
  @premium_user "PREMIUM_USER"
  @free_user "FREE_USER"

  def super_admin, do: @super_admin
  def admin, do: @admin
  def premium_user, do: @premium_user
  def free_user, do: @free_user
  def default_role, do: @free_user
end
