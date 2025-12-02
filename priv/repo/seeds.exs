# Script to seed initial roles, permissions, and admin user
# Run with: mix run priv/repo/seeds.exs

alias Adminex.Repo
alias Adminex.Schemas.{Role, Permission, User, RolePermission}
import Ecto.Query

IO.puts("🌱 Seeding database...")

# ============================================
# ROLES
# ============================================
IO.puts("Creating roles...")

roles_data = [
  %{name: "SUPER_ADMIN", description: "Acceso total al sistema"},
  %{name: "ADMIN", description: "Administrador con permisos limitados"},
  %{name: "PREMIUM_USER", description: "Usuario con funciones premium"},
  %{name: "FREE_USER", description: "Usuario gratuito estándar"}
]

roles =
  Enum.map(roles_data, fn data ->
    case Repo.get_by(Role, name: data.name) do
      nil ->
        %Role{}
        |> Role.changeset(data)
        |> Repo.insert!()
        |> tap(fn r -> IO.puts("  ✅ Created role: #{r.name}") end)

      existing ->
        IO.puts("  ⏭️  Role exists: #{existing.name}")
        existing
    end
  end)

roles_map = Map.new(roles, fn r -> {r.name, r} end)

# ============================================
# PERMISSIONS
# ============================================
IO.puts("\nCreating permissions...")

permissions_data = [
  # Admin
  %{code: "admin.access", description: "Acceso al panel de administración"},

  # Users
  %{code: "users.read", description: "Ver usuarios"},
  %{code: "users.create", description: "Crear usuarios"},
  %{code: "users.update", description: "Actualizar/deshabilitar usuarios"},
  %{code: "users.delete", description: "Eliminar usuarios"},

  # Roles
  %{code: "roles.read", description: "Ver roles"},
  %{code: "roles.create", description: "Crear roles"},
  %{code: "roles.update", description: "Actualizar roles"},
  %{code: "roles.delete", description: "Eliminar roles"},

  # Permissions
  %{code: "permissions.read", description: "Ver permisos"},
  %{code: "permissions.create", description: "Crear permisos"},
  %{code: "permissions.update", description: "Actualizar permisos"},
  %{code: "permissions.delete", description: "Eliminar permisos"},

  # Profile
  %{code: "profile.read", description: "Ver perfil propio"},
  %{code: "profile.update", description: "Actualizar perfil propio"}
]

permissions =
  Enum.map(permissions_data, fn data ->
    case Repo.get_by(Permission, code: data.code) do
      nil ->
        %Permission{}
        |> Permission.changeset(data)
        |> Repo.insert!()
        |> tap(fn p -> IO.puts("  ✅ Created permission: #{p.code}") end)

      existing ->
        IO.puts("  ⏭️  Permission exists: #{existing.code}")
        existing
    end
  end)

permissions_map = Map.new(permissions, fn p -> {p.code, p} end)

# ============================================
# ROLE-PERMISSION ASSIGNMENTS
# ============================================
IO.puts("\nAssigning permissions to roles...")

role_permissions = %{
  "SUPER_ADMIN" => [
    "admin.access",
    "users.read", "users.create", "users.update", "users.delete",
    "roles.read", "roles.create", "roles.update", "roles.delete",
    "permissions.read", "permissions.create", "permissions.update", "permissions.delete",
    "profile.read", "profile.update"
  ],
  "ADMIN" => [
    "admin.access",
    "users.read", "users.create", "users.update",
    "roles.read",
    "permissions.read",
    "profile.read", "profile.update"
  ],
  "PREMIUM_USER" => [
    "profile.read", "profile.update"
  ],
  "FREE_USER" => [
    "profile.read", "profile.update"
  ]
}

Enum.each(role_permissions, fn {role_name, permission_codes} ->
  role = roles_map[role_name]

  Enum.each(permission_codes, fn code ->
    permission = permissions_map[code]

    # Check if association exists
    existing = Repo.get_by(RolePermission, role_id: role.id, permission_id: permission.id)

    if is_nil(existing) do
      %RolePermission{}
      |> RolePermission.changeset(%{role_id: role.id, permission_id: permission.id})
      |> Repo.insert!()

      IO.puts("  ✅ #{role_name} <- #{code}")
    end
  end)
end)

# ============================================
# SUPER ADMIN USER
# ============================================
IO.puts("\nCreating super admin user...")

super_admin_email = "feriveragom@gmail.com"
super_admin_role = roles_map["SUPER_ADMIN"]

case Repo.get_by(User, email: super_admin_email) do
  nil ->
    %User{}
    |> User.oauth_changeset(%{
      email: super_admin_email,
      name: "Fernando Rivera Gomez",
      provider: "google",
      provider_uid: "super_admin_seed",
      role_id: super_admin_role.id
    })
    |> Repo.insert!()

    IO.puts("  ✅ Created super admin: #{super_admin_email}")

  existing ->
    # Update role if needed
    if existing.role_id != super_admin_role.id do
      existing
      |> Ecto.Changeset.change(%{role_id: super_admin_role.id})
      |> Repo.update!()

      IO.puts("  🔄 Updated #{super_admin_email} to SUPER_ADMIN")
    else
      IO.puts("  ⏭️  Super admin exists: #{super_admin_email}")
    end
end

IO.puts("\n✨ Seeding complete!")
