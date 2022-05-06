defmodule HexaWeb.ArComponent do
  use HexaWeb, :live_component

  def render(assigns) do
    ~H"""
      <div id="ar-frame" phx-hook="Ar">
        
      </div>
    """
  end
end