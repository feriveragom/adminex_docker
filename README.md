# Instalación Manual de Erlang/OTP 25 y Elixir 1.14

## Instalar Scoop. Abre PowerShell como administrador. (Power Shell)

### Establecer la seguridad SSL/TLS manualmente para permitir la descarga del script de instalación.
```cmd
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Set-ExecutionPolicy RemoteSigned -Scope Process; Invoke-WebRequest -Uri 'https://get.scoop.sh' -UseBasicParsing | iex
```
### ¿Desea cambiar la directiva de ejecución?
```cmd
S
```

## Instalar Erlang/OTP 25 y Elixir 1.14
```bash
scoop --version
scoop uninstall erlang && scoop uninstall elixir
scoop bucket add versions && scoop install erlang@25.0.4
scoop prefix erlang
    C:\Users\mypc\scoop\apps\erlang\current

scoop install elixir@1.14.3-otp-25
scoop prefix elixir
    C:\Users\mypc\scoop\apps\elixir\current
```

## Agregar a PATH del sistema (SystemPropertiesAdvanced)
```PATH ENV SystemPropertiesAdvanced
C:\Users\mypc\scoop\apps\erlang\current\bin
C:\Users\mypc\scoop\apps\elixir\current\bin
```

```bash
elixir --version && erl -version && mix --version
    Erlang/OTP 25 [erts-13.0.4] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [jit:ns]

    Elixir 1.14.3 (compiled with Erlang/OTP 25)
    Erlang (SMP,ASYNC_THREADS) (BEAM) emulator version 13.0.4
    Erlang/OTP 25 [erts-13.0.4] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [jit:ns]

    Mix 1.14.3 (compiled with Erlang/OTP 25)

```

## Instalar HEX
```powershell
Remove-Item -Path "C:\Users\mypc\AppData\Local\mix\Cache" -Recurse -Force
Test-Path "C:\Users\mypc\AppData\Local\mix\Cache"
```
```bash
mix local.hex --force
```

## Instalar Phoenix 1.7.x 
```bash
mix archive.install hex phx_new 1.7.14 --force

mix phx.new --version
    Phoenix installer v1.7.14
```

## Crear Proyecto Phoenix
```bash
cd "d:/Personal/emprendedores" && mix phx.new adminex --database postgres

cd "d:/Personal/emprendedores/adminex" && mix deps.get
```

## Instalacion de MNESIA 
```elixir
mix.ex
    {:memento, "~> 0.3.2"}  # Wrapper amigable para Mnesia

cd d:/Personal/emprendedores/adminex && mix deps.get
cd d:/Personal/emprendedores/adminex && mix compile
```

## Github Repo:
```bash
cd d:/Personal/emprendedores/adminex && git init

cd d:/Personal/emprendedores/adminex && git add . && git commit -m "Initial commit: Phoenix 1.7 + Clean Architecture + Mnesia setup"

gh auth status

cd d:/Personal/emprendedores/adminex && gh repo create adminex --public --source=. --remote=origin --description "Administrative module with Phoenix, LiveView and Mnesia - RBAC, Audit Logs"

Tu repo está en: https://github.com/feriveragom/adminex
```

---

## 📝 Guía de Reorganización del Proyecto

### 1. Dependencia Mnesia (Memento)

En `mix.exs` agregamos:

```elixir
{:memento, "~> 0.3.2"}  # Wrapper amigable para Mnesia
```

**¿Por qué Memento?** Mnesia puro (de Erlang) tiene una API verbosa. Memento la simplifica:

```elixir
# Mnesia puro
:mnesia.transaction(fn -> :mnesia.write({User, 1, "email"}) end)

# Con Memento
Memento.transaction(fn -> Memento.Query.write(%User{id: 1, email: "email"}) end)
```

### 2. Estructura de Carpetas (Clean Architecture)

```
lib/adminex/
├── application.ex          # OTP Application
├── repo.ex                 # Ecto Repo
├── mailer.ex               # Mailer
│
├── domain/                 # 🟣 CAPA DOMAIN (entidades puras)
│   ├── user.ex             # Struct User
│   ├── role.ex             # Struct Role
│   └── permission.ex       # Struct Permission
│
├── services/               # 🟠 CAPA APPLICATION (lógica de negocio)
│   ├── user_service.ex
│   ├── role_service.ex
│   └── audit_service.ex
│
├── infra/                  # 🟢 CAPA INFRASTRUCTURE
│   └── mnesia/             # Cache con Mnesia
│       └── session_store.ex
│
└── policies/               # 🔵 Políticas de autorización
    └── policy.ex           # can?(user, permission)
```

### 3. Configurar Mnesia

En `application.ex` inicializamos Mnesia al arrancar:

```elixir
def start(_type, _args) do
  # Inicializar Mnesia antes del supervisor
  setup_mnesia()
  
  children = [
    # ... supervisores existentes
  ]
  # ...
end
```

### 4. Archivos para Gigalixir (Deploy)

| Archivo | Propósito |
|---------|-----------|
| `elixir_buildpack.config` | Versiones de Elixir/Erlang |
| `phoenix_static_buildpack.config` | Versión de Node |
| `Procfile` | Comando de inicio |

---

## ☁️ Crear Proyecto Supabase

### Pasos manuales (web):

1. Ve a [supabase.com](https://supabase.com) y crea cuenta (o login con GitHub)
2. Click **"New Project"**
3. Configura:
   - **Name:** `adminex`
   - **Database Password:** genera uno fuerte (¡guárdalo!)
   - **Region:** elige la más cercana (ej: `us-east-1`)
   - **Plan:** Free tier
4. Una vez creado, ve a **Settings → Database** o click en **"Connect"**
5. Copia el **Connection string** (modo "URI")

### Connection Strings de Supabase

Supabase proporciona dos tipos de conexión:

```bash
# Pooled connection (para la app en runtime) - Puerto 6543
DATABASE_URL="postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-1-us-east-2.pooler.supabase.com:6543/postgres?pgbouncer=true"

# Direct connection (para migraciones) - Puerto 5432
DIRECT_URL="postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-1-us-east-2.pooler.supabase.com:5432/postgres"
```

### Configurar archivos de entorno

```bash
# Crear archivo .env (NO se sube a git)
touch .env

# Crear archivo .env.example (SÍ se sube, como template)
touch .env.example
```

Contenido de `.env`:
```bash
# Database (Supabase PostgreSQL)
DATABASE_URL=postgresql://postgres.[REF]:[PASSWORD]@aws-1-us-east-2.pooler.supabase.com:6543/postgres?pgbouncer=true
DIRECT_URL=postgresql://postgres.[REF]:[PASSWORD]@aws-1-us-east-2.pooler.supabase.com:5432/postgres

# Phoenix
SECRET_KEY_BASE=generate_with_mix_phx.gen.secret
PHX_HOST=localhost

# Supabase API (opcional)
SUPABASE_URL=https://[REF].supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

### Modificar `config/dev.exs` para usar DATABASE_URL

```elixir
import Config

# Use DATABASE_URL if available (for Supabase), otherwise use local postgres
if System.get_env("DATABASE_URL") do
  config :adminex, Adminex.Repo,
    url: System.get_env("DATABASE_URL"),
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10
else
  config :adminex, Adminex.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "adminex_dev",
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10
end
```

### Probar conexión a Supabase

```bash
# Ejecutar migraciones (usa conexión directa, puerto 5432)
DATABASE_URL='postgresql://postgres.[REF]:[PASSWORD]@aws-1-us-east-2.pooler.supabase.com:5432/postgres' mix ecto.migrate

# Resultado esperado:
# Migrations already up
```

### Limpiar y crear tablas nuevas

```bash
# Listar tablas existentes
DATABASE_URL='postgresql://postgres.[REF]:[PASSWORD]@aws-1-us-east-2.pooler.supabase.com:5432/postgres' mix run -e 'Adminex.Repo.query!("SELECT table_name FROM information_schema.tables WHERE table_schema = '\''public'\''") |> Map.get(:rows) |> IO.inspect()'

# Borrar tablas existentes (si es necesario)
DATABASE_URL='...' mix run -e '
Adminex.Repo.query!("DROP TABLE IF EXISTS service_instances CASCADE")
Adminex.Repo.query!("DROP TABLE IF EXISTS service_definitions CASCADE")
Adminex.Repo.query!("DROP TABLE IF EXISTS profiles CASCADE")
Adminex.Repo.query!("DROP TABLE IF EXISTS audit_logs CASCADE")
Adminex.Repo.query!("DROP TABLE IF EXISTS role_permissions CASCADE")
Adminex.Repo.query!("DROP TABLE IF EXISTS permissions CASCADE")
Adminex.Repo.query!("DROP TABLE IF EXISTS roles CASCADE")
'
```

### Generar migraciones

```bash
mix ecto.gen.migration create_roles
mix ecto.gen.migration create_permissions
mix ecto.gen.migration create_role_permissions
mix ecto.gen.migration create_users
mix ecto.gen.migration create_audit_logs
```

### Estructura de tablas creadas

| Tabla | Columnas | Descripción |
|-------|----------|-------------|
| `roles` | id, name, description, timestamps | Roles del sistema |
| `permissions` | id, code, description, timestamps | Permisos granulares (ej: "user.create") |
| `role_permissions` | id, role_id, permission_id, timestamps | Tabla de unión N:M |
| `users` | id, email, name, password_hash, role_id, active, timestamps | Usuarios del sistema |
| `audit_logs` | id, action, resource_type, resource_id, actor_id, metadata, ip_address, user_agent, inserted_at | Log de auditoría |

---

## 🖥️ Levantar servidor local

### Compilar assets (primera vez o si hay cambios)

```bash
mix tailwind adminex && mix esbuild adminex
```

### Iniciar servidor con Supabase

```bash
DATABASE_URL='postgresql://postgres.[REF]:[PASSWORD]@aws-1-us-east-2.pooler.supabase.com:6543/postgres?pgbouncer=true' mix phx.server
```

Visita: **http://localhost:4000**

### ⚠️ Nota Windows: Symlinks

Si ves el warning de symlinks y los assets no cargan:

1. Cierra VS Code
2. Abre VS Code como **Administrador** (clic derecho → "Ejecutar como administrador")
3. Vuelve a ejecutar `mix phx.server`

Esto solo es necesario hacerlo **una vez** para habilitar symlinks en Windows.

---

## 🚀 Próximos pasos

- [ ] Configurar Gigalixir
- [ ] GitHub Actions CI/CD
- [ ] Verificar deploy completo