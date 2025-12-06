defmodule AdminexDockerWeb.Admin.UsersLive do
  @moduledoc """
  LiveView para gestión de usuarios.
  CRUD completo con UI responsive (mobile cards + desktop table).
  """
  use AdminexDockerWeb, :live_view

  alias AdminexDocker.Repo
  alias AdminexDocker.Schemas.{User, Role}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    current_user = session["current_user"]
    users = list_users()
    roles = Repo.all(Role)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:users, users)
     |> assign(:roles, roles)
     |> assign(:page_title, "Usuarios")
     |> assign(:show_modal, false)
     |> assign(:show_delete_modal, false)
     |> assign(:editing_user, nil)
     |> assign(:deleting_user_id, nil)
     |> assign(:search, "")}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    users = list_users(search)
    {:noreply, assign(socket, users: users, search: search)}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    user = Repo.get!(User, id) |> Repo.preload(:role)
    {:noreply, assign(socket, editing_user: user, show_modal: true)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_modal: false, editing_user: nil)}
  end

  @impl true
  def handle_event("save_user", %{"user" => user_params}, socket) do
    user = socket.assigns.editing_user

    case update_user(user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Usuario actualizado correctamente")
         |> assign(:show_modal, false)
         |> assign(:editing_user, nil)
         |> assign(:users, list_users(socket.assigns.search))}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    user = Repo.get!(User, id)
    new_status = !user.active

    case user |> Ecto.Changeset.change(%{active: new_status}) |> Repo.update() do
      {:ok, _} ->
        action = if new_status, do: "activado", else: "desactivado"
        {:noreply,
         socket
         |> put_flash(:info, "Usuario #{action}")
         |> assign(:users, list_users(socket.assigns.search))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error al cambiar estado")}
    end
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, show_delete_modal: true, deleting_user_id: id)}
  end

  @impl true
  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, show_delete_modal: false, deleting_user_id: nil)}
  end

  @impl true
  def handle_event("delete", _, socket) do
    user = Repo.get!(User, socket.assigns.deleting_user_id)

    case Repo.delete(user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Usuario eliminado")
         |> assign(:show_delete_modal, false)
         |> assign(:deleting_user_id, nil)
         |> assign(:users, list_users(socket.assigns.search))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error al eliminar usuario")
         |> assign(:show_delete_modal, false)
         |> assign(:deleting_user_id, nil)}
    end
  end

  # Private functions

  defp list_users(search \\ "") do
    query =
      from u in User,
        left_join: r in assoc(u, :role),
        preload: [role: r],
        order_by: [desc: u.inserted_at]

    query =
      if search != "" do
        search_term = "%#{search}%"
        from u in query, where: ilike(u.email, ^search_term) or ilike(u.name, ^search_term)
      else
        query
      end

    Repo.all(query)
  end

  defp update_user(user, params) do
    user
    |> User.changeset(params)
    |> Repo.update()
  end
end
