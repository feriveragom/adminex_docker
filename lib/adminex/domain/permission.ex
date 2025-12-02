defmodule Adminex.Domain.Permission do
  @moduledoc """
  Permission entity - Domain layer.
  Defines all available permissions in the system.
  """

  @permissions [
    # Users
    "user.create",
    "user.list",
    "user.edit",
    "user.delete",
    # Roles
    "role.create",
    "role.list",
    "role.edit",
    "role.assign",
    # Permissions
    "permission.list",
    # Logs
    "log.list"
  ]

  @doc "Returns all available permissions"
  def all, do: @permissions

  @doc "Checks if a permission is valid"
  def valid?(permission), do: permission in @permissions
end
