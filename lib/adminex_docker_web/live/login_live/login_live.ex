defmodule AdminexDockerWeb.LoginLive do
  use AdminexDockerWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    # Si ya está autenticado, redirigir al home
    if session["current_user"] do
      {:ok, push_navigate(socket, to: "/")}
    else
      {:ok, assign(socket, :page_title, "Iniciar sesión")}
    end
  end
end
