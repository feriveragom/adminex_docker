defmodule AdminexDockerWeb.Plugs.RequirePermission do
  @moduledoc """
  Plug que verifica si el usuario tiene un permiso específico.
  Retorna 403 si no tiene el permiso.

  Uso en router:
    plug RequirePermission, permission: "admin.access"
  """
  import Plug.Conn
  import Phoenix.Controller

  alias AdminexDocker.Services.UserService

  def init(opts), do: opts

  def call(conn, opts) do
    required_permission = Keyword.fetch!(opts, :permission)
    user = conn.assigns[:current_user]

    cond do
      is_nil(user) ->
        conn
        |> put_flash(:error, "Debes iniciar sesión")
        |> redirect(to: "/login")
        |> halt()

      has_permission?(user, required_permission) ->
        conn

      true ->
        conn
        |> put_status(:forbidden)
        |> put_view(AdminexDockerWeb.ErrorHTML)
        |> render("403.html")
        |> halt()
    end
  end

  defp has_permission?(user, permission_code) do
    # El user en session tiene :email, buscamos en DB
    case user do
      %{email: email} when is_binary(email) ->
        case UserService.get_by_email(email) do
          nil -> false
          db_user -> UserService.has_permission?(db_user, permission_code)
        end

      _ ->
        false
    end
  end
end
