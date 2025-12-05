defmodule AdminexDocker.Infra.Mnesia.SessionStore do
  @moduledoc """
  Mnesia-based session store using Memento.
  Used for caching sessions and temporary data.

  NOTE: On Gigalixir with ephemeral filesystem, Mnesia data
  is lost on deploy. Use PostgreSQL for persistent data.
  """

  use Memento.Table,
    attributes: [:id, :user_id, :token, :data, :expires_at, :inserted_at],
    index: [:user_id, :token],
    type: :set

  @session_ttl_seconds 86_400  # 24 hours

  @doc """
  Creates a new session for a user.
  """
  def create_session(user_id, data \\ %{}) do
    now = DateTime.utc_now()
    expires_at = DateTime.add(now, @session_ttl_seconds, :second)

    session = %__MODULE__{
      id: generate_id(),
      user_id: user_id,
      token: generate_token(),
      data: data,
      expires_at: expires_at,
      inserted_at: now
    }

    case Memento.transaction(fn -> Memento.Query.write(session) end) do
      {:ok, session} -> {:ok, session}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets a session by token.
  """
  def get_by_token(token) do
    case Memento.transaction(fn ->
      Memento.Query.select(__MODULE__, {:==, :token, token})
    end) do
      {:ok, [session | _]} ->
        if DateTime.compare(session.expires_at, DateTime.utc_now()) == :gt do
          {:ok, session}
        else
          delete(session.id)
          {:error, :expired}
        end

      {:ok, []} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets all sessions for a user.
  """
  def get_by_user(user_id) do
    case Memento.transaction(fn ->
      Memento.Query.select(__MODULE__, {:==, :user_id, user_id})
    end) do
      {:ok, sessions} -> {:ok, sessions}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes a session by ID.
  """
  def delete(id) do
    case Memento.transaction(fn ->
      case Memento.Query.read(__MODULE__, id) do
        nil -> {:error, :not_found}
        session -> Memento.Query.delete_record(session)
      end
    end) do
      {:ok, :ok} -> :ok
      {:ok, {:error, reason}} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes all sessions for a user (logout from all devices).
  """
  def delete_all_for_user(user_id) do
    case get_by_user(user_id) do
      {:ok, sessions} ->
        Enum.each(sessions, &delete(&1.id))
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Cleans up expired sessions.
  """
  def cleanup_expired do
    now = DateTime.utc_now()

    case Memento.transaction(fn ->
      Memento.Query.all(__MODULE__)
    end) do
      {:ok, sessions} ->
        expired =
          sessions
          |> Enum.filter(&(DateTime.compare(&1.expires_at, now) != :gt))

        Enum.each(expired, &delete(&1.id))
        {:ok, length(expired)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private helpers

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  defp generate_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
