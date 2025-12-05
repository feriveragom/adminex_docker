defmodule AdminexDockerWeb.AdminLive do
  use AdminexDockerWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]

    # TODO: Verificar permisos de admin aquí
    # Por ahora, cualquier usuario autenticado puede ver

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Admin Panel")}
  end
end
