defmodule HexaWeb.MapLive do
  use HexaWeb, :live_view

  alias HexaWeb.MapComponent
  alias HexaWeb.LayoutComponent
  alias Hexa.ImageLibrary
  alias HexaWeb.Endpoint
  alias HexaWeb.HexaLive.ImageUploadFormComponent

  def render(assigns) do
    ~H"""
    <.title_bar>
      Map
      <:actions>
        <%= if @selected_mode do %>
          <.button id="upload-btn" primary phx-click="upload-selected-hexa">
            <.icon name={:upload}/><span class="ml-2">Upload Hexa</span>
          </.button>
          <.button id="cancel-upload-btn" primary phx-click="cancel-selection">
            <.icon name={:x}/><span class="ml-2">Cancel</span>
          </.button>
        <% end %>
      </:actions>
    </.title_bar>

    <div class="max-w-3xl px-4 mx-auto mt-6">
      <.live_component module={MapComponent} id="map" class= {if @selected_mode, do: "move-down-map"}/>
    </div>
    <%= if @show do %>
      <div class={"fixed z-10 inset-0 overflow-y-auto #{if @show, do: "fade-in", else: "hidden"}"} aria-labelledby="modal-title" role="dialog" aria-modal="true">
        <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen">&#8203;</span>
          <div
            class={"#{if @show, do: "fade-in-scale", else: "hidden"} sticky inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle sm:max-w-xl sm:w-full sm:p-6"}
            phx-click-away="hide-modal"
          >
            <img src={@image_url} />
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  def mount(_parmas, _session, socket) do
    %{current_user: current_user} = socket.assigns
    {
      :ok,
      socket
      |> assign(:current_user, current_user)
      |> assign(:show, false)
      |> assign(:selected_mode, false)
    }
  end

  def handle_params(_params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, push_event(socket, "reload-map", %{})}
  end

  def handle_event("cancel-selection", _we, socket) do
    {
      :noreply,
      socket
      |> assign(:selected_coord, nil)
      |> assign(:selected_mode, false)
      |> push_event("reload-map", %{})
    }
  end

  def handle_event("upload-selected-hexa", _we, socket) do
    {
      :noreply,
      show_upload(socket, socket.assigns.selected_coord)
    }
  end


  def handle_event("map-clicked", %{"lon" => _lon, "lat" => _lat} = coord, socket) do
    {
      :noreply,
      socket
      |> assign(:selected_mode, true)
      |> assign(:selected_coord, coord)
    }
  end

  def handle_event("map-clicked", properties, socket) do
    {
      :noreply,
      socket
      |> assign(:show, true)
      |> assign(:image_url, properties |> List.first() |> Map.get("image_url"))
    }
  end

  def handle_event("user-location", %{"lon" => _lon, "lat" => _lat}, socket) do
    {
      :noreply,
      socket
    }
  end

  def handle_event("hide-modal", %{}, socket) do
    {
      :noreply,
      socket
      |> assign(:show, false)
    }
  end

  defp show_upload(socket, coord) do
      socket
      |> assign(:image, %ImageLibrary.Image{})
      |> assign(:selected_coord, nil)
      |> assign(:selected_mode, false)
      |> show_upload_modal(coord)
  end

  defp show_upload_modal(socket, coord) do
    LayoutComponent.show_modal(ImageUploadFormComponent, %{
      id: :new,
      confirm: {"Save", type: "submit", form: "image-form"},
      patch: Routes.map_path(Endpoint, :index),
      image: socket.assigns.image,
      title: "Upload hexa",
      current_user: socket.assigns.current_user,
      clicked_coord: coord
    })

    socket
  end
end
