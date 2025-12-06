defmodule AdminexDockerWeb.AdminLive do
  use AdminexDockerWeb, :live_view

  alias AdminexDocker.Repo
  alias AdminexDocker.Schemas.{User, Role, Permission, AuditLog}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]

    today = Date.utc_today()
    start_of_day = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")

    logs_today =
      AuditLog
      |> where([l], l.inserted_at >= ^start_of_day)
      |> Repo.aggregate(:count)

    stats = %{
      users: Repo.aggregate(User, :count),
      roles: Repo.aggregate(Role, :count),
      permissions: Repo.aggregate(Permission, :count),
      logs_today: logs_today
    }

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:stats, stats)
     |> assign(:page_title, "Admin Panel")}
  end
end
