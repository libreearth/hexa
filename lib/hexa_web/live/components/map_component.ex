defmodule HexaWeb.MapComponent do
  use HexaWeb, :live_component

  def render(assigns) do
    ~H"""
      <div id="map" phx-hook="Map" class="h-full" phx-update="ignore"></div>
    """
  end
end
