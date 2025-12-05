defmodule AdminexDocker.Domain.Permission do
  @moduledoc """
  Permission entity - Domain layer.
  Pure struct without database dependencies.
  Permissions are defined in the database, not hardcoded.
  """

  @enforce_keys [:code]
  defstruct [:id, :code, :description, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: binary() | nil,
          code: String.t(),
          description: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
