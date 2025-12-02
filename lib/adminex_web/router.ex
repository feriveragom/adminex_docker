defmodule AdminexWeb.Router do
  use AdminexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AdminexWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AdminexWeb.Plugs.FetchCurrentUser
  end

  pipeline :auth do
    plug AdminexWeb.Plugs.RequireAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Rutas públicas (login) - usa layout auth
  scope "/", AdminexWeb do
    pipe_through :browser

    live_session :public, layout: {AdminexWeb.Layouts, :auth} do
      live "/login", LoginLive, :index
    end
  end

  # OAuth routes (públicas)
  scope "/auth", AdminexWeb do
    pipe_through :browser

    # Logout primero (antes de /:provider para evitar conflicto)
    # Usamos GET para simplificar - logout es idempotente
    get "/logout", AuthController, :logout

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Pipeline para rutas de admin (requiere permiso admin.access)
  pipeline :admin do
    plug AdminexWeb.Plugs.RequirePermission, permission: "admin.access"
  end

  # Rutas protegidas (requieren autenticación)
  scope "/", AdminexWeb do
    pipe_through [:browser, :auth]

    live "/", HomeLive, :index
    live "/profile", ProfileLive, :index
  end

  # Rutas de admin (requieren permiso admin.access)
  scope "/", AdminexWeb do
    pipe_through [:browser, :auth, :admin]

    live "/admin", AdminLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AdminexWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:adminex, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AdminexWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
