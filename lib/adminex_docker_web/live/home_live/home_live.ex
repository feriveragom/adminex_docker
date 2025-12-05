defmodule AdminexDockerWeb.HomeLive do
  use AdminexDockerWeb, :live_view

  # Override del layout default :app
  # use Phoenix.LiveView, layout: {AdminexDockerWeb.Layouts, :sidebar}

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Inicio")}
  end
end
