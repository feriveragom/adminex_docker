defmodule AdminexDocker.Repo do
  use Ecto.Repo,
    otp_app: :adminex_docker,
    adapter: Ecto.Adapters.Postgres
end
