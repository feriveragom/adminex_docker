defmodule AdminexDocker.Schemas.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "permissions" do
    field :code, :string
    field :description, :string

    many_to_many :roles, AdminexDocker.Schemas.Role, join_through: "role_permissions"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:code, :description])
    |> validate_required([:code])
    |> unique_constraint(:code)
  end
end
