defmodule AdminexWeb.ProfileLive do
  use AdminexWeb, :live_view

  alias Adminex.Services.UserService

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]

    # Cargar usuario con rol y permisos desde PostgreSQL
    {role, permissions} =
      case current_user do
        %{email: email} when is_binary(email) ->
          case UserService.get_by_email(email) do
            nil ->
              {"Sin rol", []}

            db_user ->
              db_user = Adminex.Repo.preload(db_user, role: :permissions)

              role_name = if db_user.role, do: db_user.role.name, else: "Sin rol"

              perms =
                if db_user.role && db_user.role.permissions do
                  Enum.map(db_user.role.permissions, fn p ->
                    %{code: p.code, description: p.description}
                  end)
                else
                  []
                end

              {role_name, perms}
          end

        _ ->
          {"Sin rol", []}
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:role, role)
     |> assign(:permissions, permissions)
     |> assign(:page_title, "Mi Perfil")}
  end
end
