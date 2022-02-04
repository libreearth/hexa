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
    """
  end
    
  def mount(_parmas, _session, socket) do
    {:ok, socket}
  end
end