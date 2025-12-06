defmodule AdminexDockerWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  use Timex

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false

  attr :size, :string,
    default: "3xl",
    values: ~w(sm md lg xl 2xl 3xl 5xl 7xl),
    doc: "the size of the modal"

  attr :on_cancel, JS, default: %JS{}
  attr :hidden_close_button, :boolean, default: false
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-show={show_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-40 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class={["w-full p-3 sm:p-4 lg:py-6",
            @size == "sm" && "max-w-sm",
            @size == "md" && "max-w-md",
            @size == "lg" && "max-w-lg",
            @size == "xl" && "max-w-xl",
            @size == "2xl" && "max-w-2xl",
            @size == "3xl" && "max-w-3xl",
            @size == "5xl" && "max-w-5xl",
            @size == "7xl" && "max-w-7xl"
          ]}>
          <%!-- phx-click-away={JS.exec("data-cancel", to: "##{@id}")} --%>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white px-6 py-8 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-8">
                <button
                  :if={not @hidden_close_button}
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-my-3 -ml-3 -mr-6 flex-none opacity-20 hover:opacity-40"
                  aria-label="close"
                >
                  <.svg name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      phx-hook="Flash"
      role="alert"
      class={[
        "fixed top-2 right-10 mr-2 w-max z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      style="max-width: calc(80%);"
      {@rest}
    >
      <div class="relative text-sm mr-4">
        <span class={[
          "mr-0.5 text-sm font-semibold leading-6",
          is_nil(@title) && "inline",
          not is_nil(@title) && "flex items-center justify-start"
        ]}>
          <.svg :if={@kind == :info} name="hero-information-circle-mini" class="h-5 w-5" />
          <.svg :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-5 w-5" />
          <p :if={@title} class="ml-1.5"><%= @title %></p>
        </span>
        <p class={["text-sm leading-5 max-w-screen break-words", is_nil(@title) && "inline", not is_nil(@title) && "mt-2"]}>
          <%= msg %>
        </p>
      </div>
      <button type="button" class="group absolute top-0.5 right-1 px-1" aria-label="close">
        <.svg name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title="Se ha perdido la conexión de Internet."
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        Intentando reconectar con el servidor
        <.svg name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="¡Algo va mal!"
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        Por favor, manténgase a la espera mientras nos recuperamos.
        <.svg name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true

  slot :actions, doc: "the slot for form actions, such as a submit button" do
    attr :class, :string
  end

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <%= render_slot(@inner_block, f) %>
      <div :for={action <- @actions} class={Map.get(action, :class, "")}>
        <%= render_slot(action, f) %>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-md bg-indigo-600 hover:bg-indigo-500 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :entries, :list, doc: "the options for the radio buttons in the fieldset"
  attr :container_class, :string, default: "", doc: "fieldset css class"
  attr :class, :string, default: "", doc: "css class for card contariner "
  attr :rest, :global

  slot :legend do
    attr :class, :string
  end

  slot :radio, required: true do
    attr :class, :string
  end

  def radios_fieldset(%{field: %Phoenix.HTML.FormField{value: value}} = assigns) do
    assigns =
      update(assigns, :entries, fn entries ->
        Enum.map(entries, fn
          %{name: name} = entry ->
            Map.merge(entry, %{checked: name == value})
        end)
      end)

    ~H"""
    <fieldset phx-feedback-for={@field.name} class={@container_class}>
      <legend :if={@legend != []} class={List.first(@legend)[:class]}><%= render_slot(@legend) %></legend>
      <div class={@class}>
        <.label :if={@radio != []} :for={entry <- @entries} for={"#{@field.id}_#{entry.name}"} class={List.first(@radio)[:class]}>
          <div class="absolute inset-0 flex h-6 items-center">
            <input
              type="radio"
              name={@field.name}
              id={"#{@field.id}_#{entry.name}"}
              value={entry.name}
              class="h-4 w-4 border-gray-300 text-primary focus:ring-primary"
              checked={entry.checked}
              {@rest}
            />
          </div>
          <%= render_slot(@radio, entry) %>
        </.label>
      </div>
    </fieldset>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :container_class, :string, default: "", doc: "container css class"

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week inline-prefix custom_radio toggle decimal)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :checked_value, :string, doc: "the current value for radios inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :prefix, :string, default: "", doc: "Prefix for text inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step mandatory)

  attr :input_class, :string, default: "", doc: "additional css classes for the input element"

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name} class={@container_class}>
      <label class="flex items-center gap-3">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input type="checkbox" id={@id} name={@name} value="true" checked={@checked} {@rest} />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "toggle"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name} class={@container_class}>
      <label class="flex items-center gap-1.5 text-sm leading-6 text-gray-500">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="sr-only"
          {@rest}
        />
        <div
          class={[
            "relative inline-flex h-5 w-10 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
            @checked && "bg-primary",
            not @checked && "bg-gray-200"
          ]}
          role="switch"
        >
          <span class={[
            "pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
            @checked && "translate-x-5",
            not @checked && "translate-x-0"
          ]}>
          </span>
        </div>
        <%= if @inner_block != [], do: render_slot(@inner_block) %>
        <span :if={@inner_block == []} class="text-sm">
          <%= @label %>
        </span>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "custom_radio"} = assigns) do
    ~H"""
    <input
      type="radio"
      id={@id}
      name={@name}
      value={@value}
      checked={@checked}
      class="sr-only"
      {@rest}
    />
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@container_class}>
      <.label for={@id}>
        <span class="inline-flex gap-x-1">
          <span><%= @label %></span>
          <span :if={get_in(@rest, [:mandatory]) == true} class="text-red-600">*</span>
        </span>
      </.label>
      <select
        id={@id}
        name={@name}
        class={[
          "mt-1 block w-full rounded-md border bg-white shadow-sm ring-0 focus:ring-0 sm:text-sm sm:text-sm sm:leading-6",
          "phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-gray-400",
          @errors == [] && "border-gray-300 focus:border-gray-400",
          @errors != [] && "border-red-400 focus:border-red-400"
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@container_class}>
      <.label :if={@label} for={@id}>
        <span class="inline-flex gap-x-1">
          <span><%= @label %></span>
          <span :if={get_in(@rest, [:mandatory]) == true} class="text-red-600">*</span>
        </span>
      </.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-1 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "inline-prefix"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@container_class}>
      <%= if @label !=nil do %>
      <.label for={@id}>
        <span class="inline-flex gap-x-1">
          <span><%= @label %></span>
          <span :if={get_in(@rest, [:mandatory]) == true} class="text-red-600">*</span>
        </span>
      </.label>
      <%end%>
      <div class={[
        "mt-1 flex rounded-md shadow-sm text-gray-900 border ring-0",
        "phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-gray-400",
        @errors == [] && "border-gray-300 focus:border-gray-400",
        @errors != [] && "border-red-400 focus:border-red-400",
        @input_class
      ]}>
        <span class="inline-flex items-center rounded-l-md pl-3 pr-0.5 text-gray-500 sm:text-sm sm:leading-6">
          <%= @prefix %>
        </span>
        <input
          type="text"
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value("text", @value)}
          class="block w-full min-w-0 flex-1 rounded-none rounded-r-md border-0 text-gray-900 pl-1 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"

          {@rest}
        />
      </div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "search"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@container_class}>
      <label for={@id} class="sr-only">Search</label>
      <div class="relative">
        <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
          <.svg name="hero-magnifying-glass" class="h-5 w-5 text-gray-400" />
        </div>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "mt-1 block w-full pl-10 pr-3 shadow-sm rounded-md text-gray-900 focus:ring-0 sm:text-sm sm:leading-6",
            "phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-gray-400",
            @errors == [] && "border-gray-300 focus:border-gray-400",
            @errors != [] && "border-red-400 focus:border-red-400",
            get_in(@rest, [:readonly]) == true && "bg-gray-300"
          ]}
          {@rest}
        />
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
    </div>
    """
  end

  def input(%{type: "range"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@container_class}>
      <.label for={@id}>
        <span class="inline-flex gap-x-1">
          <span><%= @label %></span>
          <span :if={get_in(@rest, [:mandatory]) == true} class="text-red-600">*</span>
        </span>
      </.label>
      <div class="flex space-x-2">
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value || get_in(@rest, [:min]))}
          class={[
            "mt-1 block w-full shadow-sm rounded-md text-gray-900 focus:ring-0 sm:text-sm sm:leading-6 cursor-pointer",
            "phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-gray-400",
            @errors == [] && "border-gray-300 focus:border-gray-400",
            @errors != [] && "border-red-400 focus:border-red-400",
            get_in(@rest, [:readonly]) == true && "bg-gray-300"
          ]}
          {@rest}
        />
        <span>
          <%= @value || get_in(@rest, [:min]) %>
        </span>
      </div>

      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "decimal"} = assigns) do
    ~H"""
    <div
      id={"container-#{@id}"}
      phx-feedback-for={@name}
      class={@container_class}
      phx-hook="DecimalInputHook"
    >
      <.label for={@id}>
        <span class="inline-flex gap-x-1">
          <span><%= @label %></span>
          <span :if={get_in(@rest, [:mandatory]) == true} class="text-red-600">*</span>
        </span>
      </.label>
      <div class={[
        "relative mt-1 rounded-md shadow-sm border",
        "phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-gray-400",
        @errors == [] && "border-gray-300 focus:border-gray-400",
        @errors != [] && "border-red-400 focus:border-red-400"
      ]}>
        <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
          <span class="text-gray-500 sm:text-sm sm:leading-6">$</span>
        </div>
        <input
          type="text"
          name={@name}
          id={@id}
          value={@value}
          class={[
            "block w-full rounded-md text-gray-900 focus:ring-0 sm:text-sm sm:leading-6 placeholder:text-gray-400 pl-7 pr-12 border-0",
            get_in(@rest, [:readonly]) == true && "bg-gray-300/80"
          ]}
          onkeypress="return event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)"
          {@rest}
        />
        <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
          <span class="text-gray-500 sm:text-sm sm:leading-6" id="price-currency">CLP</span>
        </div>
      </div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@container_class}>
      <.label for={@id}>
        <span class="inline-flex gap-x-1">
          <span><%= @label %></span>
          <span :if={get_in(@rest, [:mandatory]) == true} class="text-red-600">*</span>
        </span>
      </.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-1 block w-full shadow-sm rounded-md text-gray-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-gray-400",
          @errors == [] && "border-gray-300 focus:border-gray-400",
          @errors != [] && "border-red-400 focus:border-red-400",
          get_in(@rest, [:readonly]) == true && "bg-gray-300/80",
          @input_class
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :string, default: "block text-sm font-medium leading-6 text-gray-900"
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class={@class}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-1 flex items-center gap-1 text-sm leading-5 text-red-600 phx-no-feedback:hidden">
      <.svg name="hero-exclamation-circle-mini" class="h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil
  attr :title, :string, required: true

  slot :inner_block
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header>
      <div class="flex justify-between gap-x-4">
        <div>
          <h1 class={@class}><%= @title %></h1>
          <p :if={@subtitle != []} class="mt-1 text-sm leading-6">
            <%= render_slot(@subtitle) %>
          </p>
        </div>
        <div class="flex-none"><%= render_slot(@actions) %></div>
      </div>
      <%= render_slot(@inner_block) %>
    </header>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil
  attr :show, :boolean, required: true

  slot :inner_block

  def empty(assigns) do
    ~H"""
    <div
      :if={@show}
      class={["rounded-lg border-2 border-dashed border-gray-300 p-8 text-center", @class]}
    >
      <div class="my-6">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.
  """
  attr :class, :string, default: ""
  attr :rows, :list, required: true

  attr :row_class, :string,
    default:
      "group flex justify-between items-center py-1.5 px-4 sm:px-6 text-sm leading-6 text-gray-500"

  attr :row_item, :any, default: &Function.identity/1

  slot :col do
    attr :class, :string
  end

  def ul(assigns) do
    ~H"""
    <ul role="list" class={@class}>
      <li
        :for={row <- @rows}
        class={@row_class}
      >
        <div :for={col <- @col} class={col[:class]}>
            <%= render_slot(col, @row_item.(row)) %>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.svg name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a Tooltip element

  ## Examples

      <.tooltip class="px-4 py-2 font-medium text-white bg-black border border-white rounded-md">
        Editar
      </.tooltip>
  """
  attr :class, :string, default: nil
  attr :prefix, :string, default: "tt"
  slot :inner_block, required: true

  def tooltip(assigns) do
    ~H"""
    <div id={random_id(@prefix)} class={["tooltip", @class]} role="tooltip" phx-hook="TooltipHook">
      <%= render_slot(@inner_block) %>
      <div class="arrow" data-popper-arrow></div>
    </div>
    """
  end

  def random_id(prefix), do: "#{prefix}_#{Base.url_encode64(UUID.uuid4(), padding: false)}"

  # #FIRMADOX CUSTOM COMPONENTS
  # @doc """
  #   Componente para un toggle en un form
  # """

  # attr :id, :any
  # attr :name, :any
  # attr :label, :string, default: nil
  # attr :field, Phoenix.HTML.FormField,
  #   doc: "a form field struct retrieved from the form, for example: @form[:email]"
  # attr :errors, :list
  # attr :rest, :global, include: ~w(disabled form readonly)
  # attr :class, :string, default: nil
  # slot :inner_block

  # def toggle(assigns) do
  #   new_assigns = assign(assigns, :type, "toggle")

  #   input(new_assigns)
  # end

  @doc """
    Componente que renderiza iconos en formato SVG.
  """
  attr :name, :string,
    required: true,
    doc: """
      Nombre del icono.
      Es un atributo requerido.
      Para iconos desde `Heroicon`, se debe especificar en el nombre el prefijo `hero-`. Por defecto, se utiliza el sufijo `-outline`, pero puedes agregar `-solid` y `-mini`.
    """,
    examples: [
      "hero-x-mark-solid",
      "https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600",
      "b0ce023f-8eac-4b0b-a6e3-7d769b762b64"
    ]

  attr :type, :string,
    default: "local",
    values: ~w(local url uniqueid),
    doc: """
      Define la forma de obtener el icono.
      Por defecto se usa, `local`
      -`local` indica que se buscará el icono alojado en el servidor en la ruta `priv/static/svg`
      -`url` indica que se obtiene el icono desde una ruta
      -`uniqueid` indica que se buscará el contenido del icono en Alberto.
    """

  attr :class, :any,
    default: "",
    doc: "Agrega clases CSS, acepta valores en forma de lista o como cadena"

  attr :rest, :global

  def svg(%{name: "hero-" <> _} = assigns), do: ~H"<span class={[@name, @class]} {@rest} />"
  def svg(%{:type => "url"} = assigns), do: ~H"<img src={@name} class={@class} {@rest} />"
  def svg(assigns), do: ~H"<%= svg_path(assigns) %>"

  defp svg_path(%{type: "uniqueid", name: name, class: class}) do
    {:safe,
     cond do
       not String.valid?(name) ->
         "<img class=#{css_class(class)} src=\"#{content(name) |> extmake()}\" />"

       true ->
         name
         |> content()
         |> Floki.attr("svg", "class", fn _ -> css_class(class) end)
         |> Floki.raw_html()
     end}
  end

  defp svg_path(%{:name => name} = assigns) do
    {:safe,
     System.fetch_env!("APP_NAME")
     |> String.to_atom()
     |> Application.app_dir("priv/static/svg/#{name}.svg")
     |> File.read()
     |> loadsvg
     |> Floki.parse_fragment()
     |> insert_class(get_in(assigns, [Access.key(:class, [])]))}
  end

  defp insert_class({:error, html}, _), do: raise("No se puede parsear el html\n#{html}")

  defp insert_class({:ok, html}, class) when is_nil(class) or class == [],
    do: Floki.raw_html(html)

  defp insert_class({:ok, html}, class) do
    Floki.attr(html, "svg", "class", fn _ -> css_class(class) end)
    |> Floki.raw_html()
  end

  defp loadsvg({:ok, result}), do: String.trim(result)

  defp loadsvg(_),
    do: "<svg class='h-5 w-20'><text x='0' y='15' fill='red'>Not Found</text></svg>"

  # Capturando extension
  defp extmake(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>> = val),
    do: "data:image/png;base64,#{Base.encode64(val)}"

  defp extmake(<<0xFF, 0xD8, _::binary>> = val),
    do: "data:image/jpeg;base64,#{Base.encode64(val)}"

  defp extmake(_val), do: ""

  # Leer contenido de alberto
  def content(unique_id) when is_binary(unique_id),
    do: Firmadox.Alberto.NodeService.nodecontent_m(unique_id) |> content()

  def content({:ok, info}), do: info
  def content(_ignore), do: ""

  @doc """
    Componente que renderiza un Menu basico.
  """
  attr :id, :string, required: true
  attr :label, :string, default: ""
  attr :class, :any
  attr :width, :string, default: "w-64"

  slot :inner_block, required: true
  slot :title

  def navmenu(assigns) do
    ~H"""
    <div class="relative">
      <button type="button" phx-click={toggle("#navmenu-#{@id}")} class={@class}>
        <%= if @title != [], do: render_slot(@title), else: @label %>
      </button>
      <div
        class={[
          "hidden absolute right-0 z-10 mt-2 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none",
          @width
        ]}
        role="menu"
        id={"navmenu-#{@id}"}
        aria-orientation="vertical"
        tabindex="-1"
        phx-click-away={hide("#navmenu-#{@id}")}
        phx-window-keydown={hide("#navmenu-#{@id}")}
      >
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, default: ""
  attr :class, :any

  slot :inner_block, required: true
  slot :title

  def navmenutoggle(assigns) do
    ~H"""
    <div class="relative">
      <button type="button" phx-click={toggle("#navmenutoggle-#{@id}")} class={@class}>
        <%= if @title != [], do: render_slot(@title), else: @label %>
      </button>
      <div
        class={[
          "hidden relative bg-white py-1 focus:outline-none"
        ]}
        role="menu"
        id={"navmenutoggle-#{@id}"}
        aria-orientation="vertical"
        tabindex="-1"
        phx-click-away={hide("#navmenutoggle-#{@id}")}
        phx-window-keydown={hide("#navmenutoggle-#{@id}")}
      >
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc """
    Componente que renderiza la fecha de acuerdo al timezone del usuario.
  """

  attr :date, :string, required: true
  attr :timezone, :string, default: Timezone.name_of(0)
  attr :class, :any, default: ""

  def local_date(assigns) do
    ~H"""
    <time datetime={@date} class={@class}>
      <%= Firmadox.Utils.datetime_from(@date, &format(Timezone.convert(&1, @timezone), @timezone)) %>
    </time>
    """
  end

  def format(%DateTime{} = date, timezone) do
    if(Firmadox.Helpers.Datetime.today?(date, timezone)) do
      Timex.format!(date, "%H:%M", :strftime)
    else
      if(Firmadox.Helpers.Datetime.this_year?(date, timezone)) do
        Timex.lformat!(date, "%e %b", "es", :strftime)
      else
        Timex.format!(date, "{D}/{M}/{YY}")
      end
    end
  end

  def format(_date, _timezone), do: ""

  def css_class(class) when is_list(class), do: Enum.join(class, " ")
  def css_class(class) when is_binary(class), do: class
  def css_class(_class), do: ""

  @doc """
    Loading State component for two moments
    1- When try get data from alberto
    2- When payment state is pending
  """
  attr :show, :boolean, default: true
  attr :class, :string, default: "mx-auto flex flex-col space-y-4 max-w-md items-center"

  def confirmation_loading(assigns) do
    ~H"""
    <div :if={@show} class={@class}>
      <.svg
        name="loading"
        type="local"
        class="w-16 h-16 text-gray-200 animate-spin dark:text-gray-600 fill-primary"
      />
      <p class="text-sm md:text-lg text-gray-900">
        Por favor, espera mientras confirmamos tu compra.
      </p>
    </div>
    """
  end

  attr :show, :boolean, default: true
  attr :message, :string, default: ""
  attr :class, :string, default: "mx-auto flex flex-col space-y-4 max-w-md items-center"

  def confirmation_loading_params(assigns) do
    ~H"""
    <div :if={@show} class={@class}>
      <.svg
        name="loading"
        type="local"
        class="w-16 h-16 text-gray-200 animate-spin dark:text-gray-600 fill-primary"
      />
      <p class="text-sm md:text-lg text-gray-900">
        <%= @message %>
      </p>
    </div>
    """
  end

  ## JS Commands
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def toggle(js \\ %JS{}, selector) do
    JS.toggle(
      js,
      to: selector,
      in:
        {"transition ease-out duration-100", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"},
      out:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  def show_menu(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}",
      transition: {"transition-opacity ease-linear duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-bg",
      transition:
        {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"}
    )
  end

  def hide_menu(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}",
      transition: {"transition-opacity ease-linear duration-300", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-bg",
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # You can make use of gettext to translate error messages by
    # uncommenting and adjusting the following code:

    # if count = opts[:count] do
    #   Gettext.dngettext(FirmadoxWeb.Gettext, "errors", msg, msg, count, opts)
    # else
    #   Gettext.dgettext(FirmadoxWeb.Gettext, "errors", msg, opts)
    # end

    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
