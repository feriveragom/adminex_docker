defmodule AdminexDockerWeb.Router do
  use AdminexDockerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AdminexDockerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AdminexDockerWeb.Plugs.FetchCurrentUser
  end

  pipeline :auth do
    plug AdminexDockerWeb.Plugs.RequireAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Rutas públicas (login) - usa layout auth
  scope "/", AdminexDockerWeb do
    pipe_through :browser

    live_session :public, layout: {AdminexDockerWeb.Layouts, :auth} do
      live "/login", LoginLive, :index
    end
  end

  # OAuth routes (públicas)
  scope "/auth", AdminexDockerWeb do
    pipe_through :browser

    # Logout primero (antes de /:provider para evitar conflicto)
    # Usamos GET para simplificar - logout es idempotente
    get "/logout", AuthController, :logout

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Pipeline para rutas de admin (requiere permiso admin.access)
  pipeline :admin do
    plug AdminexDockerWeb.Plugs.RequirePermission, permission: "admin.access"
  end

  # Rutas protegidas (requieren autenticación)
  scope "/", AdminexDockerWeb do
    pipe_through [:browser, :auth]

    live "/", HomeLive, :index
    live "/profile", ProfileLive, :index
  end

  # Rutas de admin (requieren permiso admin.access)
  scope "/admin", AdminexDockerWeb do
    pipe_through [:browser, :auth, :admin]

    live "/", AdminLive, :index
    live "/users", Admin.UsersLive, :index
    live "/roles", Admin.RolesLive, :index
    live "/permissions", Admin.PermissionsLive, :index
    live "/audit", Admin.AuditLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AdminexDockerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:adminex_docker, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AdminexDockerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
