defmodule Adminex.Policies.Policy do
  @moduledoc """
  Authorization policy - checks if a user can perform an action.
  Permission-driven, NOT role-driven.
  """

  alias Adminex.Domain.Permission

  @doc """
  Checks if a user has a specific permission.

  ## Examples

      iex> Policy.can?(%{permissions: ["user.list", "user.create"]}, "user.list")
      true

      iex> Policy.can?(%{permissions: ["user.list"]}, "user.delete")
      false
  """
  def can?(%{permissions: permissions}, permission) when is_list(permissions) do
    Permission.valid?(permission) and permission in permissions
  end

  def can?(%{role: %{permissions: permissions}}, permission) when is_list(permissions) do
    Permission.valid?(permission) and permission in permissions
  end

  def can?(_, _), do: false

  @doc """
  Checks if a user has ALL of the specified permissions.
  """
  def can_all?(user, permissions) when is_list(permissions) do
    Enum.all?(permissions, &can?(user, &1))
  end

  @doc """
  Checks if a user has ANY of the specified permissions.
  """
  def can_any?(user, permissions) when is_list(permissions) do
    Enum.any?(permissions, &can?(user, &1))
  end
end
