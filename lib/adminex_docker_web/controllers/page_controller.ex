defmodule AdminexDockerWeb.PageController do
  use AdminexDockerWeb, :controller

  def home(conn, _params) do
    current_user = get_session(conn, :current_user)
    render(conn, :home, layout: false, current_user: current_user)
  end
end
