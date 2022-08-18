defmodule HexaWeb.MapLive do
  use HexaWeb, :live_view

  alias HexaWeb.MapComponent
  alias HexaWeb.MapLayoutComponent
  alias HexaLib.ImageLibrary
  alias HexaWeb.Endpoint
  alias HexaWeb.HexaLive.ImageUploadFormComponent

  def render(assigns) do
    ~H"""
      <div id="map-wrapper" class="h-full">
        <.live_component module={MapComponent} id="map"/>
        <%= if @selected_mode do %>
          <div class="inset-center bg-white p-2 rounded z-10 flex gap-1">
            <.button id="upload-btn" primary phx-click="upload-selected-hexa">
              <.icon name={:upload}/><span class="m-2">Upload</span>
            </.button>
            <.button id="cancel-upload-btn"  phx-click="cancel-selection">
              <.icon name={:x}/><span class="m-2">Cancel</span>
            </.button>
          </div>
        <% end %>
        <.live_component module={HexaWeb.MapLayoutComponent} id="maplayout" />

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
      </div>
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
      |> assign(:full_screen, false)
    }
  end

  def handle_params(_params, _url, socket) do
    MapLayoutComponent.hide_modal()
    {:noreply, push_event(socket, "reload-map", %{})}
  end

  def handle_event("full-screen", _full, socket) do
    {
      :noreply,
      socket
      |> assign(:full_screen, true)
    }
  end

  def handle_event("not-full-screen", _full, socket) do
    {
      :noreply,
      socket
      |> assign(:full_screen, false)
    }
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
    MapLayoutComponent.show_modal(ImageUploadFormComponent, %{
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
