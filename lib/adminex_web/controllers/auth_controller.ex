defmodule AdminexWeb.AuthController do
  @moduledoc """
  Controller for OAuth authentication with Google using Assent.
  """
  use AdminexWeb, :controller

  alias Assent.Strategy.Google

  @doc """
  Initiates the OAuth flow by redirecting to Google.
  """
  def request(conn, %{"provider" => "google"}) do
    config()
    |> Google.authorize_url()
    |> case do
      {:ok, %{url: url, session_params: session_params}} ->
        conn
        |> put_session(:oauth_session_params, session_params)
        |> redirect(external: url)

      {:error, error} ->
        conn
        |> put_flash(:error, "Error al iniciar autenticación: #{inspect(error)}")
        |> redirect(to: ~p"/login")
    end
  end

  def request(conn, %{"provider" => provider}) do
    conn
    |> put_flash(:error, "Proveedor no soportado: #{provider}")
    |> redirect(to: ~p"/login")
  end

  @doc """
  Handles the OAuth callback from Google.
  """
  def callback(conn, %{"provider" => "google"} = params) do
    session_params = get_session(conn, :oauth_session_params)

    config()
    |> Keyword.put(:session_params, session_params)
    |> Google.callback(params)
    |> case do
      {:ok, %{user: user_info, token: _token}} ->
        handle_successful_auth(conn, user_info)

      {:error, error} ->
        conn
        |> put_flash(:error, "Error de autenticación: #{inspect(error)}")
        |> redirect(to: ~p"/login")
    end
  end

  def callback(conn, %{"provider" => provider}) do
    conn
    |> put_flash(:error, "Proveedor no soportado: #{provider}")
    |> redirect(to: ~p"/login")
  end

  @doc """
  Logs out the user by clearing the session.
  """
  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Sesión cerrada exitosamente")
    |> redirect(to: ~p"/login")
  end

  # Private functions

  defp config do
    [
      client_id: System.get_env("GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("GOOGLE_CLIENT_SECRET"),
      redirect_uri: redirect_uri()
    ]
  end

  defp redirect_uri do
    host = System.get_env("PHX_HOST", "localhost")
    port = System.get_env("PORT", "4000")
    scheme = if host == "localhost", do: "http", else: "https"

    if host == "localhost" do
      "#{scheme}://#{host}:#{port}/auth/google/callback"
    else
      "#{scheme}://#{host}/auth/google/callback"
    end
  end

  defp handle_successful_auth(conn, user_info) do
    # user_info contains: sub, email, name, picture, email_verified, etc.
    email = user_info["email"]
    name = user_info["name"] || user_info["email"]

    # TODO: Create or find user in database
    # For now, just store in session

    conn
    |> delete_session(:oauth_session_params)
    |> put_session(:current_user, %{
      email: email,
      name: name,
      picture: user_info["picture"],
      provider: "google",
      provider_uid: user_info["sub"]
    })
    |> put_flash(:info, "¡Bienvenido, #{name}!")
    |> redirect(to: ~p"/")
  end
end
