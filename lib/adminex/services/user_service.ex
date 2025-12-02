defmodule Adminex.Services.UserService do
  @moduledoc """
  User business logic service.
  Orchestrates domain operations and authorization.
  """

  alias Adminex.Domain.User
  alias Adminex.Policies.Policy

  @doc """
  Lists all users (requires user.list permission).
  """
  def list(actor) do
    if Policy.can?(actor, "user.list") do
      # TODO: Implement with repository
      {:ok, []}
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Gets a user by ID (requires user.read permission).
  """
  def get(id, actor) do
    if Policy.can?(actor, "user.read") do
      # TODO: Implement with repository
      {:error, :not_found}
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Creates a new user (requires user.create permission).
  """
  def create(attrs, actor) do
    if Policy.can?(actor, "user.create") do
      # TODO: Implement with repository
      user = %User{
        id: generate_id(),
        email: attrs[:email],
        name: attrs[:name],
        role_id: attrs[:role_id],
        active: true,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      {:ok, user}
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates a user (requires user.update permission).
  """
  def update(id, attrs, actor) do
    if Policy.can?(actor, "user.update") do
      # TODO: Implement with repository
      {:error, :not_found}
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a user (requires user.delete permission).
  """
  def delete(id, actor) do
    if Policy.can?(actor, "user.delete") do
      # TODO: Implement with repository
      {:error, :not_found}
    else
      {:error, :unauthorized}
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
