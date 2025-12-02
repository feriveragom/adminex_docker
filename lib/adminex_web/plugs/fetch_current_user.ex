defmodule AdminexWeb.Plugs.FetchCurrentUser do
  @moduledoc """
  Plug que carga el usuario actual de la sesión al conn.assigns.
  No bloquea si no hay usuario (para páginas públicas).
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    assign(conn, :current_user, get_session(conn, :current_user))
  end
end
