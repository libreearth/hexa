defmodule HexaWeb.ArLive do
  use HexaWeb, :live_view

  alias HexaWeb.ArComponent

  def render(assigns) do
    ~H"""
    <.title_bar>
      <div id="towrite">Ar exploration</div>
    </.title_bar>

    <div class="max-w-3xl px-4 mx-auto mt-6">
      <.live_component module={ArComponent} id="ar"/>
    </div>
    """
  end

  def mount(_parmas, _session, socket) do
    {
      :ok,
      socket
    }
  end
end
