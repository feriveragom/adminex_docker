# Guía: Crear Proyecto desde Template AdminEx

## 🎯 ¿Qué es AdminEx?

**Proyecto + Template** en uno:

| Rol | Descripción |
|-----|-------------|
| **MVP Demo** | App funcional desplegada en Gigalixir, accesible online |
| **Template** | Se clona para crear nuevos proyectos con toda la infra lista |

---

## 🏗️ Stack por proyecto

```
┌─────────────────────────────────────┐
│          App Elixir/Phoenix         │
│                                     │
│  ┌─────────────┐   ┌─────────────┐  │
│  │   Mnesia    │   │   Ecto      │  │
│  │   (RAM)     │   │   (SQL)     │  │
│  └──────┬──────┘   └──────┬──────┘  │
└─────────┼─────────────────┼─────────┘
          │                 │
          ▼                 ▼
    ┌───────────┐     ┌───────────┐
    │  Sesiones │     │ PostgreSQL│
    │  (caché)  │     │ (Supabase)│
    └───────────┘     └───────────┘
```

| BD | Propósito | Persistencia |
|----|-----------|--------------|
| **PostgreSQL** | Usuarios, roles, permisos, logs | ✅ Permanente |
| **Mnesia** | Sesiones activas (caché rápido) | ❌ Se pierde al reiniciar |

---

## 🌐 Límites del Tier Gratuito

| Plataforma | Límite | Estrategia |
|------------|--------|------------|
| **Gigalixir** | 1 app corriendo | Escalar a 0 réplicas para "pausar" |
| **Supabase** | 2 proyectos activos | Pausar proyectos no usados |
| **Google OAuth** | Ilimitado | Sin límites para autenticación |

---

## 🔐 Google OAuth (Compartido)

El proyecto `adminex-oauth` en Google Cloud proporciona autenticación OAuth para todos los proyectos clonados de este template.

### ¿Por qué un proyecto OAuth compartido?

```
┌─────────────────────────────────────────────────────────┐
│  Google Cloud Project: "adminex-oauth"                  │
│                                                         │
│  Credenciales OAuth configuradas una vez                │
│  - Client ID (compartido)                               │
│  - Client Secret (compartido)                           │
│  - Redirect URIs: múltiples apps                        │
└─────────────────────────────────────────────────────────┘
          │
          ▼
    ┌─────────────┬─────────────┬─────────────┐
    │  AdminEx    │  Proyecto2  │  Proyecto3  │
    │ localhost   │  app1.com   │  app2.com   │
    └─────────────┴─────────────┴─────────────┘
```

### Configurar OAuth para nuevo proyecto clonado

1. Ve a [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=adminex-oauth)
2. Click en el client "AdminEx"
3. En **Authorized JavaScript origins**, agrega tu dominio:
   - `https://tu-app.gigalixirapp.com`
4. En **Authorized redirect URIs**, agrega:
   - `https://tu-app.gigalixirapp.com/auth/google/callback`
5. Click **Save**

### Variables de entorno requeridas

```bash
# .env
GOOGLE_CLIENT_ID=949847859878-p92a065ejloe6uqct4djlbaqoim7btg6.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=tu_secret_aqui
```

---

## 🔄 Estrategia: Rotar Apps (1 activa a la vez)

```
GIGALIXIR:
├── adminex    (réplicas=1) ✅ ONLINE
├── mi_crm     (réplicas=0) 💤 dormida
└── mi_tienda  (réplicas=0) 💤 dormida

SUPABASE:
├── adminex_db    (activa) ✅
├── mi_crm_db     (pausada) 💤
└── mi_tienda_db  (pausada) 💤
```

### Comandos para escalar réplicas

```bash
# === PAUSAR app (0 réplicas = no consume recursos) ===
# Desde el directorio del proyecto:
gigalixir ps:scale --replicas=0

# O especificando la app desde cualquier lugar:
gigalixir ps:scale --replicas=0 -a nombre_app

# === REACTIVAR app (volver a 1 réplica) ===
# Desde el directorio del proyecto:
gigalixir ps:scale --replicas=1

# O especificando la app desde cualquier lugar:
gigalixir ps:scale --replicas=1 -a nombre_app
```

> 💡 **Tip:** Al escalar a 0, la app deja de consumir recursos pero conserva toda su configuración.
> Los datos en PostgreSQL/Supabase NO se pierden.

### Rotar entre múltiples apps (tier gratuito)

```bash
# 1. PAUSAR app actual
cd d:/Personal/emprendedores/adminex
gigalixir ps:scale --replicas=0

# 2. REACTIVAR otra app
cd d:/Personal/emprendedores/mi_crm
# 2.1. Reactivar BD en Supabase (dashboard → Resume Project)
# 2.2. Escalar app en Gigalixir
gigalixir ps:scale --replicas=1
```

---

## 🚀 Crear nuevo proyecto desde template

### Paso 1: Clonar

```bash
git clone https://github.com/feriveragom/adminex.git MI_PROYECTO
cd MI_PROYECTO
git remote remove origin
# Opcional: crear tu propio repo
git remote add origin https://github.com/TU_USUARIO/MI_PROYECTO.git
```

### Paso 2: Crear BD en Supabase

1. [supabase.com](https://supabase.com) → Login con GitHub
2. **New Project**:
   - Name: `mi_proyecto`
   - Database Password: Click "Generate a password" (¡guárdalo!)
   - Region: la más cercana
3. Esperar ~2 minutos a que se aprovisione

### Paso 3: Obtener credenciales de Supabase

| Dato | Dónde encontrarlo |
|------|-------------------|
| **Project Ref** | URL: `supabase.com/dashboard/project/[AQUÍ]` |
| **DATABASE_URL** | Connect → Transaction Pooler (puerto 6543) |
| **DIRECT_URL** | Connect → Session Pooler o Direct (puerto 5432) |
| **SUPABASE_URL** | Settings → Data API → Project URL |
| **SUPABASE_ANON_KEY** | Settings → API Keys → "Legacy anon, service_role API keys" → anon public |

### Paso 4: Configurar

```bash
cp .env.example .env
```

Editar `.env` con tus valores:
- `DATABASE_URL`: Reemplazar `[YOUR-PASSWORD]` con tu password
- `DIRECT_URL`: Reemplazar `[YOUR-PASSWORD]` con tu password
- `SECRET_KEY_BASE`: ejecutar `mix phx.gen.secret`
- `PHX_HOST`: `localhost` (dev) o `tu-app.gigalixirapp.com` (prod)
- `SUPABASE_URL`: URL del proyecto
- `SUPABASE_ANON_KEY`: anon public key

### Paso 5: Instalar, migrar y poblar BD

> ⚠️ **Importante:** Elixir NO carga `.env` automáticamente.
> `System.get_env("DATABASE_URL")` lee variables del sistema operativo, no del archivo.
> Debes exportar las variables antes de ejecutar comandos mix.

```bash
mix deps.get

# Cargar variables de .env
export $(cat .env | grep -v '^#' | xargs)

# Crear tablas (migraciones)
mix ecto.migrate

# Poblar datos iniciales (roles, permisos, admin)
mix run priv/repo/seeds.exs
```

El seed crea:
- **4 Roles:** SUPER_ADMIN, ADMIN, PREMIUM_USER, FREE_USER
- **18 Permisos:** admin.access, users.*, roles.*, permissions.*, profile.*
- **1 Usuario:** feriveragom@gmail.com como SUPER_ADMIN

> 💡 **Nuevo usuario OAuth:** Al hacer login con Google, si el email no existe en BD,
> se crea automáticamente con rol `FREE_USER`.

### Paso 6: Configurar `~/.bashrc` (una sola vez)

El archivo `~/.bashrc` está en tu home (fuera del proyecto):
- **Windows:** `C:\Users\<tu_usuario>\.bashrc`
- **Mac/Linux:** `~/.bashrc`

Se ejecuta automáticamente cada vez que abres una terminal.

```bash
# Crear ~/.bashrc con alias para Phoenix y PATH para Gigalixir CLI (Windows)
echo 'alias phx="export \$(cat .env | grep -v \"^#\" | xargs) && iex -S mix phx.server"' > ~/.bashrc
echo "export PATH=\"\$PATH:/c/Users/$USER/AppData/Local/Programs/Python/Python313/Scripts\"" >> ~/.bashrc
source ~/.bashrc
```

> **Nota:** `$USER` se reemplaza automáticamente con tu nombre de usuario.
> En Mac/Linux el PATH de Python es diferente (normalmente ya está en PATH).

#### Verificar que funcionó:
```bash
cat ~/.bashrc
# Debería mostrar:
# alias phx="export $(cat .env | grep -v "^#" | xargs) && iex -S mix phx.server"
# export PATH="$PATH:..."
```

#### ¿Qué hace el alias `phx`?
- ✅ Carga variables de `.env` del proyecto actual
- ✅ Inicia servidor Phoenix
- ✅ Abre consola interactiva IEx para probar funciones
- ✅ Permite `recompile()` sin reiniciar

### Paso 7: Compilar assets e iniciar

```bash
# Si usas el alias:
phx

# Si no, cargar .env manualmente:
export $(cat .env | grep -v '^#' | xargs)
mix tailwind adminex && mix esbuild adminex
mix phx.server
# Visitar http://localhost:4000
```

### Paso 8: Deploy en Gigalixir (opcional)

```bash
# Instalar CLI (Windows)
python -m pip install gigalixir

# Verificar (el PATH ya se configuró en Paso 6)
gigalixir version

# Login (elige una opción)
gigalixir login           # Email + password
gigalixir login:google    # Abre navegador para OAuth

# Crear app
gigalixir apps:create --name mi-proyecto

# Configurar variables de entorno (cargar .env primero)
export $(cat .env | grep -v '^#' | xargs)
gigalixir config:set DATABASE_URL="$DATABASE_URL"
gigalixir config:set SECRET_KEY_BASE="$SECRET_KEY_BASE"
gigalixir config:set PHX_HOST="mi-proyecto.gigalixirapp.com"
gigalixir config:set GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID"
gigalixir config:set GOOGLE_CLIENT_SECRET="$GOOGLE_CLIENT_SECRET"

# Agregar remote de Gigalixir
gigalixir git:remote mi-proyecto

# Deploy
git push gigalixir main
```

---

## 📋 Tablas PostgreSQL (se crean con migrate)

```
roles ──────┬──────▶ role_permissions ◀────── permissions
            │
            ▼
users ─────────────▶ audit_logs
```

| Tabla | Campos clave |
|-------|--------------|
| `roles` | id, name, description |
| `permissions` | id, code (ej: "users.create") |
| `role_permissions` | role_id, permission_id |
| `users` | id, email, name, role_id, active, provider, provider_uid, picture |
| `audit_logs` | action, resource_type, resource_id, actor_id, metadata |

---

## 🔐 Sistema RBAC (Permission-Driven)

### Roles por defecto

| Rol | Descripción | Acceso a /admin |
|-----|-------------|-----------------|
| `SUPER_ADMIN` | Acceso total | ✅ |
| `ADMIN` | Admin limitado (no puede eliminar) | ✅ |
| `PREMIUM_USER` | Usuario de pago | ❌ |
| `FREE_USER` | Usuario gratuito (default) | ❌ |

### Permisos disponibles

| Recurso | Permisos |
|---------|----------|
| **admin** | `admin.access` |
| **users** | `users.read`, `users.create`, `users.update`, `users.delete` |
| **roles** | `roles.read`, `roles.create`, `roles.update`, `roles.delete` |
| **permissions** | `permissions.read`, `permissions.create`, `permissions.update`, `permissions.delete` |
| **profile** | `profile.read`, `profile.update` |

### Verificar permisos en código

```elixir
# En un plug (router)
plug RequirePermission, permission: "admin.access"

# En un servicio
alias Adminex.Services.UserService

if UserService.has_permission?(user, "users.delete") do
  # puede eliminar usuarios
end
```

### Matriz de permisos por rol

| Permiso | SUPER_ADMIN | ADMIN | PREMIUM | FREE |
|---------|:-----------:|:-----:|:-------:|:----:|
| admin.access | ✅ | ✅ | ❌ | ❌ |
| users.read | ✅ | ✅ | ❌ | ❌ |
| users.create | ✅ | ✅ | ❌ | ❌ |
| users.update | ✅ | ✅ | ❌ | ❌ |
| users.delete | ✅ | ❌ | ❌ | ❌ |
| roles.read | ✅ | ✅ | ❌ | ❌ |
| roles.create | ✅ | ❌ | ❌ | ❌ |
| roles.update | ✅ | ❌ | ❌ | ❌ |
| roles.delete | ✅ | ❌ | ❌ | ❌ |
| permissions.* | ✅ | read | ❌ | ❌ |
| profile.read | ✅ | ✅ | ✅ | ✅ |
| profile.update | ✅ | ✅ | ✅ | ✅ |

---

## 🧠 Mnesia (Sesiones)

```elixir
# Tabla: SessionStore - se crea automáticamente al iniciar la app
[:id, :user_id, :token, :data, :expires_at, :inserted_at]
```

**Comportamiento:**
- Login → crea sesión en Mnesia
- Request → busca token en Mnesia (microsegundos)
- App reinicia → Mnesia vacía, usuarios re-login

---

## 📊 Resumen

```
┌────────────────────────────────────────────────────────────┐
│  Clonar template = nuevo proyecto independiente             │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  1. git clone adminex MI_PROYECTO                           │
│  2. Crear proyecto en Supabase                              │
│  3. Configurar .env                                         │
│  4. mix ecto.migrate                                        │
│  5. mix phx.server                                          │
│                                                             │
│  Resultado: App con seguridad lista (users, roles, perms)   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```
