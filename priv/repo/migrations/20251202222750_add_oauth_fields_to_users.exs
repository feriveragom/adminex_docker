defmodule AdminexDocker.Repo.Migrations.AddOauthFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :provider, :string  # "google", "github", etc.
      add :provider_uid, :string  # ID único del proveedor
      add :picture, :string  # URL del avatar
    end

    create index(:users, [:provider, :provider_uid])
  end
end
