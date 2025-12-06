defmodule AdminexDockerWeb.Admin.AuditLive do
  @moduledoc """
  LiveView para visualizar los logs de auditoría.
  Filtros por usuario y rango de fechas (por defecto: hoy).
  """
  use AdminexDockerWeb, :live_view

  alias AdminexDocker.Repo
  alias AdminexDocker.Schemas.{AuditLog, User}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]
    users = list_users()
    today = Date.utc_today()

    socket =
      socket
      |> assign(
        current_user: current_user,
        page_title: "Auditoría",
        users: users,
        logs: [],
        user_filter: "",
        date_from: Date.to_iso8601(today),
        date_to: Date.to_iso8601(today),
        loading: true
      )

    # Cargar logs con filtro inicial
    logs = list_logs(socket.assigns)

    {:ok, assign(socket, logs: logs, loading: false)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    user_filter = params["user_id"] || ""
    date_from = params["date_from"] || socket.assigns.date_from
    date_to = params["date_to"] || socket.assigns.date_to

    socket =
      socket
      |> assign(
        user_filter: user_filter,
        date_from: date_from,
        date_to: date_to,
        loading: true
      )

    logs = list_logs(socket.assigns)

    {:noreply, assign(socket, logs: logs, loading: false)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    today = Date.utc_today()

    socket =
      socket
      |> assign(
        user_filter: "",
        date_from: Date.to_iso8601(today),
        date_to: Date.to_iso8601(today),
        loading: true
      )

    logs = list_logs(socket.assigns)

    {:noreply, assign(socket, logs: logs, loading: false)}
  end

  # Private functions

  defp list_users do
    User
    |> order_by([u], asc: u.email)
    |> Repo.all()
  end

  defp list_logs(assigns) do
    query =
      from l in AuditLog,
        left_join: a in assoc(l, :actor),
        preload: [actor: a],
        order_by: [desc: l.inserted_at],
        limit: 100

    query = filter_by_user(query, assigns.user_filter)
    query = filter_by_date_range(query, assigns.date_from, assigns.date_to)

    Repo.all(query)
  end

  defp filter_by_user(query, ""), do: query

  defp filter_by_user(query, user_id) do
    where(query, [l], l.actor_id == ^user_id)
  end

  defp filter_by_date_range(query, date_from, date_to) do
    with {:ok, from_date} <- Date.from_iso8601(date_from),
         {:ok, to_date} <- Date.from_iso8601(date_to) do
      from_datetime = DateTime.new!(from_date, ~T[00:00:00], "Etc/UTC")
      to_datetime = DateTime.new!(to_date, ~T[23:59:59], "Etc/UTC")

      query
      |> where([l], l.inserted_at >= ^from_datetime)
      |> where([l], l.inserted_at <= ^to_datetime)
    else
      _ -> query
    end
  end

  # Helper para formatear la acción como badge
  def action_color(action) do
    cond do
      String.contains?(action, "create") -> "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
      String.contains?(action, "update") -> "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"
      String.contains?(action, "delete") -> "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"
      String.contains?(action, "login") -> "bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400"
      String.contains?(action, "logout") -> "bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400"
      true -> "bg-primary-100 text-primary-700 dark:bg-primary-800 dark:text-primary-400"
    end
  end
end
