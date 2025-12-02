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

## 🔐 Google OAuth (AdminEx)

### Proyecto GCP creado (02-Dic-2025)
- **Project name:** adminex-oauth
- **Project ID:** `adminex-oauth`
- **Console:** https://console.cloud.google.com/welcome?project=adminex-oauth

### Credenciales OAuth
- **Client ID:** `949847859878-p92a065ejloe6uqct4djlbaqoim7btg6.apps.googleusercontent.com`
- **Client Secret:** En `.env` como `GOOGLE_CLIENT_SECRET`

### URIs autorizadas
| Tipo | URI |
|------|-----|
| JavaScript origins | `http://localhost:4000` |
| Redirect URI | `http://localhost:4000/auth/google/callback` |

> ⚠️ **Producción:** Agregar URIs de Gigalixir cuando esté configurado.

### Test users (modo Testing)
- `feriveragom@gmail.com`

---

## ☁️ Supabase (AdminEx)

### Proyecto creado (02-Dic-2025)
- **Name:** adminex
- **Region:** us-east-2 (East US - Ohio)
- **Project Ref:** `mxjcejukdxmfembcgpkt`
- **Dashboard:** https://supabase.com/dashboard/project/mxjcejukdxmfembcgpkt

### Connection Strings

Configuradas en `.env` (ver `.env.example`):
- `DATABASE_URL` → Pooled connection (puerto 6543) para runtime
- `DIRECT_URL` → Direct connection (puerto 5432) para migraciones

Obtener de: Supabase Dashboard → Connect → Connection String

### Migraciones ejecutadas

```bash
mix ecto.migrate
# Tablas creadas: roles, permissions, role_permissions, users, audit_logs
```

### Comandos útiles

```bash
# Listar tablas
mix run -e 'Adminex.Repo.query!("SELECT table_name FROM information_schema.tables WHERE table_schema = '\''public'\''") |> Map.get(:rows) |> IO.inspect()'

# Limpiar tablas (si necesario)
mix run -e 'Adminex.Repo.query!("DROP TABLE IF EXISTS audit_logs, role_permissions, users, permissions, roles CASCADE")'
```

---

## 🖥️ Desarrollo Local

> ⚠️ **Importante:** Elixir NO carga `.env` automáticamente.
> `System.get_env("DATABASE_URL")` lee variables del **sistema operativo**, no del archivo `.env`.
> Debes exportar las variables antes de ejecutar comandos mix.

### Configurar `~/.bashrc` (una sola vez)

El archivo `~/.bashrc` está en tu home (`C:\Users\<tu_usuario>\.bashrc` en Windows).
Se ejecuta cada vez que abres una terminal Git Bash.

```bash
# Crear ~/.bashrc con alias y PATH (Windows con Git Bash)
echo 'alias phx="export \$(cat .env | grep -v \"^#\" | xargs) && iex -S mix phx.server"' > ~/.bashrc
echo "export PATH=\"\$PATH:/c/Users/$USER/AppData/Local/Programs/Python/Python313/Scripts\"" >> ~/.bashrc
source ~/.bashrc
```

> **Nota:** `$USER` se reemplaza automáticamente con tu nombre de usuario.

### Verificar configuración

```bash
cat ~/.bashrc
# Debería mostrar:
# alias phx="export $(cat .env | grep -v "^#" | xargs) && iex -S mix phx.server"
# export PATH="$PATH:/c/Users/<tu_usuario>/..."
```

### Usar el alias

```bash
cd d:/Personal/emprendedores/adminex
phx
# Carga .env + inicia servidor + consola interactiva IEx
```

### Comandos de desarrollo

```bash
# Cargar variables manualmente (si no usas alias)
export $(cat .env | grep -v '^#' | xargs)

# Verificar que se cargaron (opcional)
echo $DATABASE_URL

# Compilar assets (primera vez)
mix tailwind adminex && mix esbuild adminex

# Iniciar servidor
mix phx.server
# O con el alias:
phx
```

Visita: **http://localhost:4000**

---

## 🚀 Deploy Automático (GitHub Actions)

El workflow `.github/workflows/deploy.yml` hace deploy automático a Gigalixir cada vez que haces push a `main` o `master`.

### Configurar Secrets en GitHub

1. Ve a tu repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"** y agrega:

| Secret | Valor |
|--------|-------|
| `GIGALIXIR_USERNAME` | Tu email de Gigalixir |
| `GIGALIXIR_PASSWORD` | Tu password de Gigalixir |
| `GIGALIXIR_APP_NAME` | Nombre de tu app (ej: `adminex`) |

### Configurar Gigalixir (primera vez)

```bash
# Instalar CLI (Windows)
python -m pip install gigalixir

# Agregar al PATH (en ~/.bashrc)
echo 'export PATH="$PATH:/c/Users/mypc/AppData/Local/Programs/Python/Python313/Scripts"' >> ~/.bashrc
source ~/.bashrc

# Verificar instalación
gigalixir version
# 1.15.0

# Login con Google
gigalixir login:google
# Abre el navegador, autentícate y vuelve a la terminal

# Crear app
gigalixir apps:create --name adminex

# Configurar variables de entorno (cargar .env primero)
export $(cat .env | grep -v '^#' | xargs)
gigalixir config:set DATABASE_URL="$DATABASE_URL"
gigalixir config:set SECRET_KEY_BASE="$SECRET_KEY_BASE"
gigalixir config:set PHX_HOST="adminex.gigalixirapp.com"
gigalixir config:set GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID"
gigalixir config:set GOOGLE_CLIENT_SECRET="$GOOGLE_CLIENT_SECRET"

# Verificar configuración
gigalixir config

# Deploy
git push gigalixir master
```

### Agregar URI de producción a Google OAuth

1. Ve a: https://console.cloud.google.com/apis/credentials?project=adminex-oauth
2. Click en el client **"AdminEx"**
3. Agrega en **Authorized JavaScript origins**:
   - `https://adminex.gigalixirapp.com`
4. Agrega en **Authorized redirect URIs**:
   - `https://adminex.gigalixirapp.com/auth/google/callback`
5. Click **Save**

---

## 🌐 URLs del Proyecto

| Entorno | URL |
|---------|-----|
| **Local** | http://localhost:4000 |
| **Producción** | https://adminex.gigalixirapp.com |
| **GitHub** | https://github.com/feriveragom/adminex |
| **Supabase** | https://supabase.com/dashboard/project/mxjcejukdxmfembcgpkt |
| **Google OAuth** | https://console.cloud.google.com/apis/credentials?project=adminex-oauth |
| **Gigalixir** | https://console.gigalixir.com/#/apps |

---

## 📚 Documentación

- **[.artifacts/ARQUITECTURA_DATOS.md](.artifacts/ARQUITECTURA_DATOS.md)** - Guía para crear nuevos proyectos desde este template

---

## 🚀 Próximos pasos

- [x] Configurar Supabase
- [x] GitHub Actions CI/CD
- [x] Cuenta Gigalixir ✅
- [x] Deploy inicial ✅ (https://adminex.gigalixirapp.com)
- [x] Google OAuth login ✅
- [ ] Seeds (admin + roles)
- [ ] RBAC completo
- [ ] Auth (login/logout)