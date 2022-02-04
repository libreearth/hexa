defmodule HexaWeb.HexaLive do
  use HexaWeb, :live_view
  
  alias HexaWeb.MapComponent

  def render(assigns) do
    ~H"""
    <.title_bar>
      My Hexas
    </.title_bar>

    <div class="max-w-3xl px-4 mx-auto mt-6">
      Here goes a list of hexas
    </div>
    """
  end
    
  def mount(_parmas, _session, socket) do
    {:ok, socket}
  end
end