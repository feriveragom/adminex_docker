defmodule AdminexDockerWeb.Admin.PermissionsLive do
  @moduledoc """
  LiveView para la gestión de permisos.
  CRUD completo de permisos del sistema.
  """
  use AdminexDockerWeb, :live_view

  alias AdminexDocker.Repo
  alias AdminexDocker.Schemas.Permission
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]
    permissions = list_permissions()

    {:ok,
     assign(socket,
       current_user: current_user,
       page_title: "Permisos",
       permissions: permissions,
       search: "",
       show_modal: false,
       editing_permission: nil,
       is_new: false
     )}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    permissions = list_permissions(search)
    {:noreply, assign(socket, permissions: permissions, search: search)}
  end

  @impl true
  def handle_event("new", _params, socket) do
    {:noreply,
     assign(socket,
       show_modal: true,
       editing_permission: %Permission{code: "", description: ""},
       is_new: true
     )}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    permission = Repo.get!(Permission, id)

    {:noreply,
     assign(socket,
       show_modal: true,
       editing_permission: permission,
       is_new: false
     )}
  end

  @impl true
  def handle_event("save_permission", %{"permission" => params}, socket) do
    result =
      if socket.assigns.is_new do
        %Permission{}
        |> Permission.changeset(params)
        |> Repo.insert()
      else
        socket.assigns.editing_permission
        |> Permission.changeset(params)
        |> Repo.update()
      end

    case result do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> put_flash(:info, if(socket.assigns.is_new, do: "Permiso creado", else: "Permiso actualizado"))
         |> assign(permissions: list_permissions(socket.assigns.search), show_modal: false)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al guardar el permiso")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    permission = Repo.get!(Permission, id)

    case Repo.delete(permission) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Permiso eliminado")
         |> assign(permissions: list_permissions(socket.assigns.search))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "No se puede eliminar el permiso (puede estar asignado a roles)")}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, editing_permission: nil)}
  end

  # Private functions

  defp list_permissions(search \\ "") do
    query =
      from p in Permission,
        order_by: [asc: p.code]

    query =
      if search != "" do
        search_term = "%#{search}%"
        where(query, [p], ilike(p.code, ^search_term) or ilike(p.description, ^search_term))
      else
        query
      end

    Repo.all(query)
    |> Enum.group_by(fn p -> p.code |> String.split(".") |> hd() end)
  end
end
