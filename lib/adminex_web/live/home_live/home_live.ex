defmodule AdminexWeb.HomeLive do
  use AdminexWeb, :live_view

  # Override del layout default :app
  # use Phoenix.LiveView, layout: {AdminexWeb.Layouts, :sidebar}

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Inicio")}
  end
end
