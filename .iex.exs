# Configuración de IEx para AdminEx
# Colores y formato mejorado para la consola

# Colores para diferentes tipos de datos
IEx.configure(
  colors: [
    enabled: true,
    eval_result: [:cyan, :bright],
    eval_error: [:red, :bright],
    eval_info: [:yellow],
    syntax_colors: [
      number: :magenta,
      atom: :cyan,
      string: :green,
      boolean: :magenta,
      nil: :red,
      list: :white,
      tuple: :white,
      map: :white,
      binary: :green
    ]
  ],
  default_prompt:
    [
      # Púrpura para AdminEx
      "\e[35m",
      # Nombre de la app
      "adminex",
      "\e[0m",
      # Contador en cyan
      "(\e[36m%counter\e[0m)",
      # Flecha verde
      "\e[32m>\e[0m "
    ]
    |> IO.chardata_to_string(),
  alive_prompt:
    [
      "\e[35m",
      "adminex",
      "\e[0m",
      "(\e[36m%counter\e[0m)",
      "@\e[33m%node\e[0m",
      "\e[32m>\e[0m "
    ]
    |> IO.chardata_to_string(),
  history_size: 100,
  inspect: [
    pretty: true,
    limit: 50,
    width: 80
  ]
)

# Alias útiles para desarrollo
alias Adminex.Repo
alias Adminex.Schemas.{User, Role, Permission, RolePermission}
alias Adminex.Services.UserService
alias Phoenix.PubSub
alias AdminexWeb.Endpoint

# Helper para ver usuarios con roles
defmodule H do
  @moduledoc "Helpers de desarrollo"

  def users do
    Repo.all(User) |> Repo.preload(:role)
  end

  def roles do
    Repo.all(Role) |> Repo.preload(:permissions)
  end

  def permissions do
    Repo.all(Permission)
  end

  def user(email) when is_binary(email) do
    Repo.get_by(User, email: email) |> Repo.preload(role: :permissions)
  end

  def perms(email) when is_binary(email) do
    case user(email) do
      nil -> []
      u -> u.role.permissions |> Enum.map(& &1.code)
    end
  end
end

# IO.puts("\n\e[35m╔═══════════════════════════════════════╗\e[0m")
# IO.puts("\e[35m║\e[0m   \e[1m🚀 AdminEx Development Console\e[0m      \e[35m║\e[0m")
# IO.puts("\e[35m╠═══════════════════════════════════════╣\e[0m")
# IO.puts("\e[35m║\e[0m  \e[36mH.users\e[0m      → Lista usuarios        \e[35m║\e[0m")
# IO.puts("\e[35m║\e[0m  \e[36mH.roles\e[0m       → Lista roles          \e[35m║\e[0m")
# IO.puts("\e[35m║\e[0m  \e[36mH.user(email)\e[0m → Busca usuario        \e[35m║\e[0m")
# IO.puts("\e[35m║\e[0m  \e[36mH.perms(email)\e[0m→ Permisos de usuario  \e[35m║\e[0m")
# IO.puts("\e[35m║\e[0m  \e[33mrecompile()\e[0m   → Recargar código      \e[35m║\e[0m")
# IO.puts("\e[35m╚═══════════════════════════════════════╝\e[0m\n")
