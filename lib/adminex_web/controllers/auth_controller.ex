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
      redirect_uri: redirect_uri(),
      authorization_params: [
        scope: "openid email profile",
        prompt: "select_account"
      ]
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
    alias Adminex.Services.UserService
    require Logger

    # Debug: ver estructura de user_info
    Logger.debug("OAuth user_info: #{inspect(user_info)}")

    # Buscar o crear usuario en la BD
    case UserService.find_or_create_from_oauth(user_info) do
      {:ok, user} ->
        # Guardar en sesión (incluye info del rol)
        conn
        |> delete_session(:oauth_session_params)
        |> put_session(:current_user, %{
          id: user.id,
          email: user.email,
          name: user.name,
          picture: user.picture,
          provider: user.provider,
          provider_uid: user.provider_uid,
          role: user.role && user.role.name
        })
        |> redirect(to: ~p"/")

      {:error, :role_not_found} ->
        conn
        |> put_flash(:error, "Error: ejecuta 'mix run priv/repo/seeds.exs' para crear roles")
        |> redirect(to: ~p"/login")

      {:error, :email_not_provided} ->
        conn
        |> put_flash(:error, "Error: Google no proporcionó email. Verifica permisos OAuth.")
        |> redirect(to: ~p"/login")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error al crear usuario: #{inspect(changeset.errors)}")
        |> redirect(to: ~p"/login")
    end
  end
end
