defmodule HexaWeb.MapLive do
  use HexaWeb, :live_view
  
  alias HexaWeb.MapComponent

  def render(assigns) do
    ~H"""
    <.title_bar>
      Map exploration
    </.title_bar>

    <div class="max-w-3xl px-4 mx-auto mt-6">
      <.live_component module={MapComponent} id="map"/> 
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
    {
      :ok, 
      socket
      |> assign(:show, false)
    }
  end

  def handle_event("map-clicked", [], socket) do
    { :noreply, socket}
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
end