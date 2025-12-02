defmodule AdminexWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug que verifica si el usuario está autenticado.
  Si no está autenticado, redirige al login.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :current_user) do
      assign(conn, :current_user, get_session(conn, :current_user))
    else
      conn
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
