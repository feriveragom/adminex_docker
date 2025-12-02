defmodule Adminex.Services.AuditService do
  @moduledoc """
  Audit logging service.
  Records all important actions for compliance and debugging.
  """

  require Logger

  @doc """
  Logs an action to the audit trail.

  ## Examples

      iex> AuditService.log(:user_created, user_id, actor: current_user)
      {:ok, log_entry}
  """
  def log(action, resource_id, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    metadata = Keyword.get(opts, :metadata, %{})

    entry = %{
      id: generate_id(),
      action: action,
      resource_id: resource_id,
      actor_id: get_actor_id(actor),
      metadata: metadata,
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent),
      inserted_at: DateTime.utc_now()
    }

    # TODO: Persist to PostgreSQL via repository
    Logger.info("AUDIT: #{action} on #{resource_id} by #{entry.actor_id}")

    {:ok, entry}
  end

  @doc """
  Lists audit logs with optional filters.
  """
  def list(filters \\ [], actor) do
    # TODO: Check permission and implement with repository
    {:ok, []}
  end

  @doc """
  Gets audit logs for a specific resource.
  """
  def for_resource(resource_id, actor) do
    # TODO: Check permission and implement with repository
    {:ok, []}
  end

  # Private helpers

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  defp get_actor_id(nil), do: "system"
  defp get_actor_id(%{id: id}), do: id
  defp get_actor_id(actor) when is_binary(actor), do: actor
end
