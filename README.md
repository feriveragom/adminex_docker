# AdminEx Docker

> 🚀 **Template de administración con Elixir/Phoenix + Google OAuth + RBAC (Dockerizado)**

## ¿Qué es AdminEx Docker?

Una versión dockerizada y lista para desarrollo local del template AdminEx. Incluye:

- ✅ **Autenticación OAuth** (Google)
- ✅ **RBAC** (Roles y Permisos granulares)
- ✅ **UI Purple Theme** (Tailwind + Dark Mode)
- ✅ **Mnesia** para sesiones (cache en memoria)
- ✅ **PostgreSQL** para persistencia
- ✅ **Nginx + SSL** para HTTPS local

## Stack

| Tecnología | Versión | Uso |
|------------|---------|-----|
| Elixir | 1.18 | Lenguaje |
| Phoenix | 1.7 | Framework Web |
| LiveView | 1.0 | UI Reactiva |
| Tailwind CSS | 3.4 | Estilos |
| Mnesia | - | Sesiones (RAM) |
| PostgreSQL | 15+ | Base de datos |
| Nginx | 1.25 | Reverse Proxy (SSL) |

---

## 🚀 Quick Start (Docker)

### Prerrequisitos

- Docker Desktop instalado y corriendo.

### Instalación y Ejecución

```bash
# 1. Clonar
git clone https://github.com/feriveragom/adminex_docker.git mi-proyecto
cd mi-proyecto

# 2. Configurar .env
cp .env.example .env
# (Opcional) Ajusta credenciales si es necesario, por defecto funcionan con Docker.

# 3. Generar certificados SSL (para HTTPS local)
mkdir certs
MSYS_NO_PATHCONV=1 openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/nginx.key -out certs/nginx.crt \
  -subj "/C=CL/ST=Region Metropolitana/L=Santiago/O=AdminEx/CN=adminex.docker.com"

# 4. Levantar servicios (App + DB + Nginx)
docker-compose up --build

# 5. Configurar base de datos (en otra terminal)
# Esto crea la BD, corre migraciones y ejecuta los seeds
docker-compose exec app mix ecto.setup
```

### Configurar Dominio Local

Para acceder vía `https://adminex.docker.com`, edita tu archivo `hosts` como **Administrador**:

**Windows:** `C:\Windows\System32\drivers\etc\hosts`
**Mac/Linux:** `/etc/hosts`

Agrega la línea:
```plaintext
127.0.0.1       adminex.docker.com
```

Visita: **https://adminex.docker.com** (Acepta la advertencia de seguridad del certificado autofirmado).
O visita directamente: **http://localhost:4000** (Sin SSL).

### Comandos Útiles

```bash
# Entrar a la consola de IEx dentro del contenedor
docker-compose exec app iex -S mix

# Correr migraciones manualmente
docker-compose exec app mix ecto.migrate

# Resetear base de datos
docker-compose exec app mix ecto.reset
```

---

## 🔐 Sistema RBAC (Permission-First)

> **Filosofía:** Se verifican **permisos**, nunca roles directamente.

### Permisos del Sistema

| Código | Descripción |
|--------|-------------|
| `home.access` | Acceder a `/` (home) |
| `profile.read` | Ver mi perfil |
| `profile.update` | Editar mi perfil |
| `admin.access` | Acceder a `/admin` |
| `users.read` | Ver lista de usuarios |
| `users.create` | Crear usuarios |
| `users.update` | Editar usuarios |
| `users.delete` | Eliminar usuarios |
| `roles.read` | Ver lista de roles |
| `roles.create` | Crear roles |
| `roles.update` | Editar roles |
| `roles.delete` | Eliminar roles |
| `permissions.read` | Ver permisos |
| `permissions.assign` | Asignar permisos a roles |

### Roles y sus Permisos

| Rol | Permisos |
|-----|----------|
| **SUPER_ADMIN** | Todos (14) |
| **ADMIN** | Todos (14) |
| **PREMIUM_USER** | `home.access`, `profile.read`, `profile.update` |
| **FREE_USER** | `home.access`, `profile.read`, `profile.update` |

### Seed Inicial

| Tipo | Datos |
|------|-------|
| **Roles** | SUPER_ADMIN, ADMIN, PREMIUM_USER, FREE_USER |
| **Usuario inicial** | `feriveragom@gmail.com` → SUPER_ADMIN |

> 💡 **Auto-registro:** Todo usuario nuevo que se loguee con Google se crea automáticamente con rol `FREE_USER`.

### Verificar Permisos en Código

```elixir
# En router (plug)
plug RequirePermission, permission: "admin.access"

# En servicio
UserService.has_permission?(user, "users.delete")
```

---

## 📝 Estructura del Proyecto (Clean Architecture)

```
lib/adminex_docker/
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