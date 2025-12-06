defmodule AdminexDockerWeb.Admin.RolesLive do
  @moduledoc """
  LiveView para la gestión de roles y asignación de permisos.
  """
  use AdminexDockerWeb, :live_view

  alias AdminexDocker.Repo
  alias AdminexDocker.Schemas.{Role, Permission}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]
    roles = list_roles()
    permissions = list_permissions()

    {:ok,
     assign(socket,
       current_user: current_user,
       page_title: "Roles",
       roles: roles,
       permissions: permissions,
       search: "",
       show_modal: false,
       show_delete_modal: false,
       editing_role: nil,
       deleting_role_id: nil,
       selected_permissions: MapSet.new(),
       is_new: false
     )}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    roles = list_roles(search)
    {:noreply, assign(socket, roles: roles, search: search)}
  end

  @impl true
  def handle_event("new", _params, socket) do
    # Cargar los permisos del rol FREE_USER como base
    free_user_permissions = get_free_user_permissions()
    
    {:noreply,
     assign(socket,
       show_modal: true,
       editing_role: %Role{name: "", description: ""},
       selected_permissions: free_user_permissions,
       is_new: true
     )}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    role = 
      Role
      |> Repo.get!(id)
      |> Repo.preload(permissions: from(p in Permission, order_by: p.code))
    
    permission_ids = role.permissions |> Enum.map(& &1.id) |> MapSet.new()

    {:noreply,
     assign(socket,
       show_modal: true,
       editing_role: role,
       selected_permissions: permission_ids,
       is_new: false
     )}
  end

  @impl true
  def handle_event("toggle_permission", %{"id" => permission_id}, socket) do
    # permission_id ya es un UUID string, no necesita conversión
    selected = socket.assigns.selected_permissions

    new_selected =
      if MapSet.member?(selected, permission_id) do
        MapSet.delete(selected, permission_id)
      else
        MapSet.put(selected, permission_id)
      end

    {:noreply, assign(socket, selected_permissions: new_selected)}
  end

  @impl true
  def handle_event("save_role", %{"role" => role_params}, socket) do
    permission_ids = MapSet.to_list(socket.assigns.selected_permissions)

    result =
      if socket.assigns.is_new do
        create_role(role_params, permission_ids)
      else
        update_role(socket.assigns.editing_role, role_params, permission_ids)
      end

    case result do
      {:ok, _role} ->
        {:noreply,
         socket
         |> put_flash(:info, if(socket.assigns.is_new, do: "Rol creado", else: "Rol actualizado"))
         |> assign(roles: list_roles(socket.assigns.search), show_modal: false, editing_role: nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al guardar el rol")}
    end
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, show_delete_modal: true, deleting_role_id: id)}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_delete_modal: false, deleting_role_id: nil)}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    role = Repo.get!(Role, socket.assigns.deleting_role_id)

    case Repo.delete(role) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rol eliminado")
         |> assign(roles: list_roles(socket.assigns.search), show_delete_modal: false, deleting_role_id: nil)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "No se puede eliminar el rol")
         |> assign(show_delete_modal: false, deleting_role_id: nil)}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, editing_role: nil)}
  end

  # Private functions

  defp list_roles(search \\ "") do
    query =
      from r in Role,
        left_join: p in assoc(r, :permissions),
        preload: [permissions: p],
        order_by: [asc: r.name]

    query =
      if search != "" do
        search_term = "%#{search}%"
        where(query, [r], ilike(r.name, ^search_term) or ilike(r.description, ^search_term))
      else
        query
      end

    Repo.all(query)
  end

  defp list_permissions do
    Permission
    |> order_by([p], asc: p.code)
    |> Repo.all()
    |> Enum.group_by(fn p -> p.code |> String.split(".") |> hd() end)
  end

  defp create_role(params, permission_ids) do
    permissions = Repo.all(from p in Permission, where: p.id in ^permission_ids)

    %Role{}
    |> Role.changeset(params)
    |> Ecto.Changeset.put_assoc(:permissions, permissions)
    |> Repo.insert()
  end

  defp update_role(role, params, permission_ids) do
    permissions = Repo.all(from p in Permission, where: p.id in ^permission_ids)

    role
    |> Repo.preload(:permissions)
    |> Role.changeset(params)
    |> Ecto.Changeset.put_assoc(:permissions, permissions)
    |> Repo.update()
  end

  defp get_free_user_permissions do
    # Obtener los permisos del rol FREE_USER
    free_user_role =
      Role
      |> where(name: "FREE_USER")
      |> preload(:permissions)
      |> Repo.one()

    if free_user_role do
      free_user_role.permissions
      |> Enum.map(& &1.id)
      |> MapSet.new()
    else
      MapSet.new()
    end
  end
end

