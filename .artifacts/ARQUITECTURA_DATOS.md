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

### Comandos para rotar

```bash
# === BAJAR app actual ===
gigalixir ps:scale --replicas=0 -a nombre_app

# === SUBIR otra app ===
# 1. Reactivar BD en Supabase (dashboard → Resume Project)
# 2. Escalar app en Gigalixir
gigalixir ps:scale --replicas=1 -a otra_app
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

### Paso 5: Instalar y crear tablas

> ⚠️ **Importante:** Elixir NO carga `.env` automáticamente.
> `System.get_env("DATABASE_URL")` lee variables del sistema operativo, no del archivo.
> Debes exportar las variables antes de ejecutar comandos mix.

```bash
mix deps.get

# Cargar variables de .env y ejecutar migraciones
export $(cat .env | grep -v '^#' | xargs) && mix ecto.migrate
```

### Paso 6: Configurar carga de `.env` (elige una opción)

#### Opción A: Alias en `.bashrc` (recomendada para desarrollo)
```bash
# Agregar a ~/.bashrc (una sola vez)
echo 'alias phx="export \$(cat .env | grep -v \"^#\" | xargs) && iex -S mix phx.server"' >> ~/.bashrc
source ~/.bashrc

# Luego solo ejecutas:
phx
```

> **Nota:** Usamos `iex -S mix phx.server` en lugar de `mix phx.server` para tener:
> - ✅ Servidor web corriendo
> - ✅ Consola interactiva IEx para probar funciones
> - ✅ Recompilar con `recompile()` sin reiniciar

#### Opción B: Librería `dotenvy` (automática)
Carga `.env` al compilar. Agregar a `mix.exs`:
```elixir
{:dotenvy, "~> 0.8.0"}
```
Y en `config/runtime.exs`:
```elixir
if config_env() == :dev do
  Dotenvy.source!([".env"])
end
```

#### Opción C: Script `run.sh`
```bash
#!/bin/bash
export $(cat .env | grep -v '^#' | xargs)
mix phx.server
```

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

# Agregar al PATH (en ~/.bashrc) - ajustar ruta según tu usuario
echo 'export PATH="$PATH:/c/Users/TU_USUARIO/AppData/Local/Programs/Python/Python313/Scripts"' >> ~/.bashrc
source ~/.bashrc

# Verificar
gigalixir version

# Login (elige una opción)
gigalixir login           # Email + password
gigalixir login:google    # Abre navegador para OAuth

# Crear app
gigalixir apps:create --name mi-proyecto

# Configurar variables de entorno
gigalixir config:set DATABASE_URL="tu_database_url"
gigalixir config:set SECRET_KEY_BASE="$(mix phx.gen.secret)"
gigalixir config:set PHX_HOST="mi-proyecto.gigalixirapp.com"

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
| `permissions` | id, code (ej: "user.create") |
| `role_permissions` | role_id, permission_id |
| `users` | id, email, password_hash, role_id, active |
| `audit_logs` | action, resource_type, resource_id, actor_id, metadata |

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
