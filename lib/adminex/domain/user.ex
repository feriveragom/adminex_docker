defmodule Adminex.Domain.User do
  @moduledoc """
  User entity - Domain layer.
  Pure struct without database dependencies.
  """

  @enforce_keys [:email]
  defstruct [:id, :email, :name, :password_hash, :role_id, :active, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: binary() | nil,
          email: String.t(),
          name: String.t() | nil,
          password_hash: String.t() | nil,
          role_id: binary() | nil,
          active: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
