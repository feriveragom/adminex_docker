# Arquitectura de Datos y Seguridad

## 🏗️ Stack de Datos (Dockerizado)

```
┌───────────────────────────────────────────────┐
│              Docker Compose                   │
│                                               │
│  ┌─────────────────┐     ┌─────────────────┐  │
│  │  Servicio: app  │     │  Servicio: db   │  │
│  │  (Phoenix 1.7)  │     │  (Postgres 15)  │  │
│  │                 │     │                 │  │
│  │  ┌───────────┐  │     │  ┌───────────┐  │  │
│  │  │  Mnesia   │  │     │  │   Data    │  │  │
│  │  │ (Session) │  │◀───▶│  │ (Volume)  │  │  │
│  │  └───────────┘  │     │  └───────────┘  │  │
│  └─────────────────┘     └─────────────────┘  │
└───────────────────────────────────────────────┘
```

| Componente | Tecnología | Propósito | Persistencia |
|------------|------------|-----------|--------------|
| **App** | Elixir/Phoenix | Lógica, UI, Sesiones | Efímera (Código en volumen) |
| **DB** | PostgreSQL 15 | Datos relacionales | ✅ Permanente (Docker Volume) |
| **Sesión** | Mnesia | Tokens de sesión activos | ❌ Volátil (RAM) |

---

## 📋 Tablas PostgreSQL

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

## 🔐 Sistema RBAC (Permission-First)

> **Filosofía:** Siempre verificar **permisos**, nunca roles directamente. Los permisos se definen en la base de datos, no en el código.

### Roles por defecto

| Rol | Descripción | Permisos |
|-----|-------------|----------|
| `SUPER_ADMIN` | Acceso total | Todos (15) |
| `ADMIN` | Acceso total | Todos (15) |
| `PREMIUM_USER` | Usuario de pago | Solo básicos (4) |
| `FREE_USER` | Usuario gratuito (default) | Solo básicos (4) |

### Lista de Permisos (15 total)

| Código | Descripción | SUPER_ADMIN/ADMIN | FREE/PREMIUM |
|--------|-------------|:-----------------:|:------------:|
| `home.access` | Acceder a `/` (home) | ✅ | ✅ |
| `profile.access` | Acceder a `/profile` | ✅ | ✅ |
| `profile.read` | Ver mi perfil | ✅ | ✅ |
| `profile.update` | Editar mi perfil | ✅ | ✅ |
| `admin.access` | Acceder a `/admin` | ✅ | ❌ |
| `users.read` | Ver lista de usuarios | ✅ | ❌ |
| `users.create` | Crear usuarios | ✅ | ❌ |
| `users.update` | Editar usuarios | ✅ | ❌ |
| `users.delete` | Eliminar usuarios | ✅ | ❌ |
| `roles.read` | Ver lista de roles | ✅ | ❌ |
| `roles.create` | Crear roles | ✅ | ❌ |
| `roles.update` | Editar roles | ✅ | ❌ |
| `roles.delete` | Eliminar roles | ✅ | ❌ |
| `permissions.read` | Ver permisos | ✅ | ❌ |
| `permissions.assign` | Asignar permisos a roles | ✅ | ❌ |

### Verificar permisos en código

```elixir
# En un plug (router)
plug RequirePermission, permission: "admin.access"

# En un servicio
alias AdminexDocker.Services.UserService

if UserService.has_permission?(user, "users.delete") do
  # puede eliminar usuarios
end

# Con Policy directamente
alias AdminexDocker.Policies.Policy

if Policy.can?(user, "roles.create") do
  # puede crear roles
end
```

### Personalización para tu proyecto

1. **Edita `priv/repo/seeds.exs`** para definir tus propios permisos y roles
2. **Ejecuta `mix ecto.reset`** para recrear la BD con los nuevos datos
3. **Los permisos NO están hardcodeados** - todo viene de PostgreSQL

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
