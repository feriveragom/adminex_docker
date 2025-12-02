defmodule Adminex.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :name, :string
    field :password_hash, :string
    field :active, :boolean, default: true
    field :provider, :string
    field :provider_uid, :string
    field :picture, :string

    belongs_to :role, Adminex.Schemas.Role

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :password_hash, :role_id, :active, :provider, :provider_uid, :picture])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:email)
  end

  @doc "Changeset para usuarios OAuth"
  def oauth_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role_id, :provider, :provider_uid, :picture])
    |> validate_required([:email, :provider, :provider_uid])
    |> unique_constraint(:email)
  end
end
