defmodule AdminexWeb.ProfileLive do
  use AdminexWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]

    # Datos mock de permisos (después vendrán de BD)
    permissions = [
      %{code: "services.view", description: "services.view"},
      %{code: "services.definition.create", description: "services.definition.create"},
      %{code: "services.definition.edit", description: "services.definition.edit"},
      %{code: "services.definition.delete", description: "services.definition.delete"}
    ]

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:role, "SUPER_ADMIN")
     |> assign(:user_id, "qh3Z1px4BTcPb12wn8Skgt9sefG3")
     |> assign(:permissions, permissions)
     |> assign(:page_title, "Mi Perfil")}
  end
end
