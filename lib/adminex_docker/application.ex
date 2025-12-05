defmodule AdminexDocker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    # Initialize Mnesia tables before starting supervision tree
    setup_mnesia()

    children = [
      AdminexDockerWeb.Telemetry,
      AdminexDocker.Repo,
      {DNSCluster, query: Application.get_env(:adminex_docker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AdminexDocker.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AdminexDocker.Finch},
      # Start a worker by calling: AdminexDocker.Worker.start_link(arg)
      # {AdminexDocker.Worker, arg},
      # Start to serve requests, typically the last entry
      AdminexDockerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AdminexDocker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AdminexDockerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Setup Mnesia tables
  # NOTE: On Gigalixir, Mnesia data is ephemeral (lost on deploy)
  # Use this only for sessions/cache, not for persistent data
  defp setup_mnesia do
    # Ensure Mnesia is started (handle already started case)
    case Memento.start() do
      :ok -> :ok
      {:error, {:already_started, :mnesia}} -> :ok
    end

    # Create tables if they don't exist
    tables = [AdminexDocker.Infra.Mnesia.SessionStore]

    Enum.each(tables, fn table ->
      case Memento.Table.create(table) do
        :ok ->
          Logger.info("Mnesia table #{table} created")

        {:error, {:already_exists, _}} ->
          Logger.debug("Mnesia table #{table} already exists")

        {:error, reason} ->
          Logger.warning("Failed to create Mnesia table #{table}: #{inspect(reason)}")
      end
    end)

    :ok
  end
end
