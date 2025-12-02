# Patrones y Anti-Patrones - AdminEx

## 🎯 Principios Fundamentales

### 1. Clean Architecture
Las dependencias DEBEN apuntar hacia adentro. Domain no sabe nada de BD o UI.

```
┌─────────────────────────────────────────────────────────┐
│                      UI / Web                            │
│  (LiveView, Controllers, Templates)                      │
├─────────────────────────────────────────────────────────┤
│                   Application                            │
│  (Services, Use Cases)                                   │
├─────────────────────────────────────────────────────────┤
│                     Domain                               │
│  (Entities, Business Rules, Policies)                    │
├─────────────────────────────────────────────────────────┤
│                 Infrastructure                           │
│  (Ecto Repos, Mnesia, Supabase Client)                   │
└─────────────────────────────────────────────────────────┘
         ▲ Las dependencias apuntan HACIA ARRIBA
```

```elixir
# ✅ Domain NO importa Ecto
defmodule Adminex.Domain.User do
  defstruct [:id, :email, :role_id]
end

# ✅ Infrastructure implementa interfaces del Domain
defmodule Adminex.Infra.UserRepo do
  @behaviour Adminex.Domain.UserRepository
  # Aquí sí usamos Ecto
end
```

### 2. Mobile-First UI
Toda UI diseñada para móviles (320px+) primero, luego pantallas grandes.

```heex
<!-- ✅ Mobile-first con Tailwind -->
<div class="p-2 sm:p-4 md:p-6 lg:p-8">
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    <!-- Cards responsive -->
  </div>
</div>

<!-- ❌ Desktop-first (NO hacer) -->
<div class="p-8 sm:p-2">  <!-- Empieza grande, reduce -->
```

**Breakpoints Tailwind:**
- Base (sin prefijo): 0px+ (móvil)
- `sm:` 640px+
- `md:` 768px+
- `lg:` 1024px+

### 3. Permission-Driven Security
Acceso controlado por **permisos granulares**, NO por roles.

```elixir
# ✅ Correcto - verificar permiso
if Policy.can?(user, "users.delete"), do: delete(user_id)

# ❌ Incorrecto - verificar rol
if user.role == :admin, do: delete(user_id)
```

---

## ✅ Patrones a Seguir

### 1. Repository Pattern
Separar acceso a datos de la lógica de negocio.
```elixir
# Behaviour (interfaz)
defmodule Adminex.Repositories.UserRepository do
  @callback get(id) :: {:ok, map()} | {:error, :not_found}
  @callback create(attrs) :: {:ok, map()} | {:error, term()}
end

# Implementación
defmodule Adminex.Repositories.Ecto.UserRepository do
  @behaviour Adminex.Repositories.UserRepository
  # ...
end
```

### 2. Service Layer
Lógica de negocio en módulos dedicados, NO en controllers.
```elixir
# ✅ Correcto
def create(conn, params) do
  case UserService.register(params) do
    {:ok, user} -> redirect(conn, to: ~p"/users")
    {:error, reason} -> render(conn, :new, error: reason)
  end
end
```

### 3. Permission-Driven RBAC
Verificar **permisos**, no roles. (Ver principio #4 arriba)

### 4. Context Pattern
Agrupar funcionalidad relacionada.
```
lib/adminex/
├── accounts/       # Contexto: usuarios, auth
├── authorization/  # Contexto: roles, permisos
└── auditing/       # Contexto: logs
```

### 5. Tuple Returns `{:ok, _}` / `{:error, _}`
Siempre retornar tuplas para operaciones que pueden fallar.
```elixir
# ✅ Correcto - tuplas claras
def create_user(attrs) do
  case Repo.insert(changeset) do
    {:ok, user} -> {:ok, user}
    {:error, changeset} -> {:error, changeset}
  end
end

# ❌ Incorrecto - raise para control de flujo
def create_user!(attrs) do
  Repo.insert!(changeset)  # Solo usar en scripts/tests
end
```

### 6. Structs sobre Maps
Usar structs para datos con estructura conocida.
```elixir
# ✅ Correcto - struct con campos definidos
defmodule User do
  @enforce_keys [:email]
  defstruct [:id, :email, :name, :role_id]
end

# Acceso estricto - error si el campo no existe
user.email   # ✅
user.foo     # ❌ KeyError inmediato

# ❌ Incorrecto - map dinámico
user = %{email: "x@y.com"}
user[:foo]   # nil silencioso - puede causar bugs
```

### 7. Pattern Matching en Funciones
Múltiples cláusulas sobre if/case cuando sea posible.
```elixir
# ✅ Correcto - pattern matching claro
def handle_response({:ok, %{status: 200, body: body}}), do: {:ok, body}
def handle_response({:ok, %{status: 404}}), do: {:error, :not_found}
def handle_response({:error, reason}), do: {:error, reason}

# ❌ Incorrecto - if/else anidados
def handle_response(response) do
  if response.ok do
    if response.status == 200 do
      {:ok, response.body}
    else
      {:error, :not_found}
    end
  else
    {:error, response.reason}
  end
end
```

### 8. Bloques Monádicos con `Error.m`
Para encadenar operaciones que pueden fallar, usar bloques monádicos.

**Reglas del bloque monádico:**
- `<-` extrae valores de `{:ok, valor}` automáticamente
- Cualquier `{:error, _}` detiene la cadena inmediatamente
- NO usar `=` dentro del bloque
- La última expresión debe usar `Error.return()` o retornar `{:ok, _}`

```elixir
# ✅ CORRECTO - Bloque monádico limpio
def create_user_with_role(attrs, role_name) do
  Error.m do
    role <- RoleService.find_by_name(role_name)
    user <- UserService.create(Map.put(attrs, :role_id, role.id))
    _log <- AuditService.log(:user_created, user.id)
    user |> Error.return()
  end
end

# ✅ CORRECTO - Debug con IO.inspect dentro del flujo
Error.m do
  result <- operacion() |> IO.inspect(label: "Debug") |> Error.return()
  result |> Error.return()
end

# ✅ CORRECTO - Logs fuera del bloque monádico
Logger.info("Iniciando operación")
Error.m do
  result <- operacion_monadica()
  result |> Error.return()
end
Logger.info("Operación completada")

# ❌ INCORRECTO - Asignación directa dentro del bloque
Error.m do
  a = operacion()           # ❌ NO usar =
  operacion() |> Error.return()  # ❌ Sin binding
end

# ❌ INCORRECTO - Logs sin binding
Error.m do
  Logger.info("Log") |> Error.return()  # ❌ Falta el binding <-
end
```

**Cuándo usar `Error.m` vs `with`:**
| Escenario | Usar |
|-----------|------|
| 2-3 operaciones simples | `with` |
| 4+ operaciones encadenadas | `Error.m` |
| Necesitas transformar errores | `Error.m` con `Error.map_error/2` |
| Código más legible/mantenible | `Error.m` |

---

## ❌ Anti-Patrones a Evitar

| Anti-Patrón | Problema | Solución |
|-------------|----------|----------|
| **Lógica en controllers** | No testeable, no reutilizable | Mover a Services/Contexts |
| **Verificar roles** | Rígido, código disperso | Verificar permisos |
| **God Modules** | >300 líneas, muchas responsabilidades | Dividir en módulos |
| **try/rescue para control de flujo** | Oculta errores, difícil de seguir | Usar `{:ok, _}` / `{:error, _}` |
| **N+1 queries** | Performance terrible | Preload/Join |
| **Strings hardcodeados** | Typos silenciosos | Usar atoms |
| **Procesos sin supervisor** | Procesos huérfanos, sin recovery | Task.Supervisor, DynamicSupervisor |
| **Acceso dinámico a maps** | `map[:key]` retorna nil silencioso | Usar structs o `map.key` |
| **Funciones multi-cláusula no relacionadas** | Difícil de entender y mantener | Separar en funciones distintas |
| **Primitive obsession** | Usar strings/ints para datos complejos | Crear structs específicos |
| **Boolean obsession** | Múltiples booleans con estados superpuestos | Usar atoms `:status` |
| **Creación dinámica de atoms** | Memory leak, límite de 1M atoms | `String.to_existing_atom/1` |
| **Config global en librerías** | No permite múltiples configuraciones | Pasar config como parámetro |
| **`use` cuando basta `import`** | Inyecta código oculto, menos legible | Preferir `import` o `alias` |

---

## Ejemplos Detallados de Anti-Patrones

### ❌ Exceptions para Control de Flujo
```elixir
# ❌ MALO - usar try/rescue para flujo normal
def read_config(path) do
  try do
    File.read!(path) |> Jason.decode!()
  rescue
    e -> {:error, e.message}
  end
end

# ✅ BUENO - usar funciones que retornan tuplas
def read_config(path) do
  with {:ok, content} <- File.read(path),
       {:ok, config} <- Jason.decode(content) do
    {:ok, config}
  end
end
```

### ❌ Primitive Obsession
```elixir
# ❌ MALO - dirección como string
def extract_postal_code(address) when is_binary(address) do
  # Parsear string es frágil y propenso a errores
end

# ✅ BUENO - struct con campos claros
defmodule Address do
  defstruct [:street, :city, :postal_code, :country]
end

def extract_postal_code(%Address{postal_code: code}), do: code
```

### ❌ Boolean Obsession
```elixir
# ❌ MALO - múltiples booleans superpuestos
def process(invoice, admin: true, editor: false) do
  # ¿Qué pasa si ambos son true?
end

# ✅ BUENO - un atom para el rol
def process(invoice, role: :admin) do
  case role do
    :admin -> # ...
    :editor -> # ...
    :viewer -> # ...
  end
end
```

### ❌ Procesos sin Supervisor
```elixir
# ❌ MALO - proceso huérfano
def start_worker do
  spawn(fn -> do_work() end)
end

# ✅ BUENO - bajo supervisión
def start_worker do
  Task.Supervisor.start_child(MyApp.TaskSupervisor, fn -> do_work() end)
end
```

---

## Ejemplo Completo: Malo vs Bueno

```elixir
# ❌ MALO: Lógica en controller + verificar rol + rescue
def delete(conn, %{"id" => id}) do
  try do
    if conn.assigns.current_user.role == :admin do
      Repo.delete!(User, id)
      redirect(conn, to: ~p"/users")
    end
  rescue
    _ -> send_resp(conn, 500, "Error")
  end
end

# ✅ BUENO: Service + verificar permiso + tuplas
def delete(conn, %{"id" => id}) do
  user = conn.assigns.current_user

  case UserService.delete(id, actor: user) do
    {:ok, _} -> redirect(conn, to: ~p"/users")
    {:error, :unauthorized} -> send_resp(conn, 403, "No permitido")
    {:error, :not_found} -> send_resp(conn, 404, "No encontrado")
  end
end
```


## Principios de Desarrollo

- Actuar como un ingeniero senior de Elixir experto.
- Analizar a fondo los requerimientos y consideraciones antes de escribir código.
- Escribir código reflexivo y mantenible con enfoque en escalabilidad y seguridad.
- Implementar patrones OTP cuando sea apropiado (GenServer, GenStage, etc.).
- Después de cada respuesta, incluir tres preguntas de seguimiento diseñadas para promover pensamiento más profundo:
    - Una pregunta estratégica de alto nivel.
    - Una pregunta práctica de implementación o toma de decisiones.
    - Una pregunta provocativa sobre casos edge o consideraciones especiales.