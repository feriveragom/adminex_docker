defmodule AdminexDocker.Services.UserService do
  @moduledoc """
  Servicio para gestión de usuarios.
  """

  import Ecto.Query
  alias AdminexDocker.Repo
  alias AdminexDocker.Schemas.{User, Role}

  @doc """
  Busca un usuario por email. Si no existe, lo crea con rol FREE_USER.
  Retorna el usuario con su rol precargado.
  """
  def find_or_create_from_oauth(oauth_info) do
    email = oauth_info["email"]

    if is_nil(email) do
      {:error, :email_not_provided}
    else
      case get_by_email(email) do
        nil -> create_from_oauth(oauth_info)
        user -> {:ok, Repo.preload(user, :role)}
      end
    end
  end

  @doc """
  Busca un usuario por email.
  """
  def get_by_email(nil), do: nil
  def get_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Crea un usuario desde información OAuth con rol por defecto.
  """
  def create_from_oauth(oauth_info) do
    with {:ok, role} <- get_default_role() do
      attrs = %{
        email: oauth_info["email"],
        name: oauth_info["name"],
        provider: "google",
        provider_uid: oauth_info["sub"],
        picture: oauth_info["picture"],
        role_id: role.id
      }

      %User{}
      |> User.oauth_changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, user} -> {:ok, Repo.preload(user, :role)}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc """
  Obtiene el rol por defecto (FREE_USER).
  """
  def get_default_role do
    case Repo.get_by(Role, name: Role.free_user()) do
      nil -> {:error, :role_not_found}
      role -> {:ok, role}
    end
  end

  @doc """
  Verifica si un usuario tiene un permiso específico.
  """
  def has_permission?(nil, _permission_code), do: false

  def has_permission?(user, permission_code) when is_struct(user) do
    user = Repo.preload(user, role: :permissions)

    case user.role do
      nil -> false
      role -> Enum.any?(role.permissions, &(&1.code == permission_code))
    end
  end

  def has_permission?(user_id, permission_code) when is_binary(user_id) do
    case Repo.get(User, user_id) do
      nil -> false
      user -> has_permission?(user, permission_code)
    end
  end

  @doc """
  Obtiene un usuario por ID con su rol y permisos precargados.
  """
  def get_with_permissions(user_id) do
    User
    |> Repo.get(user_id)
    |> Repo.preload(role: :permissions)
  end
end
