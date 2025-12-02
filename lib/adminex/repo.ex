defmodule Adminex.Repo do
  use Ecto.Repo,
    otp_app: :adminex,
    adapter: Ecto.Adapters.Postgres
end
