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
echo 'alias phx="export \$(cat .env | grep -v \"^#\" | xargs) && mix phx.server"' >> ~/.bashrc
source ~/.bashrc

# Luego solo ejecutas:
phx
```

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
gigalixir create -n mi-proyecto
gigalixir config:set DATABASE_URL="tu_url"
gigalixir config:set SECRET_KEY_BASE="$(mix phx.gen.secret)"
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
