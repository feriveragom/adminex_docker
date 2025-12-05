defmodule AdminexDocker.Domain.Role do
  @moduledoc """
  Role entity - Domain layer.
  Pure struct without database dependencies.
  """

  @enforce_keys [:name]
  defstruct [:id, :name, :description, :permissions, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: binary() | nil,
          name: String.t(),
          description: String.t() | nil,
          permissions: list(String.t()),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
