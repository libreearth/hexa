defmodule HexaWeb.ShowImageComponent do
  use HexaWeb, :live_component

  def render(assigns) do
    ~H"""
      <div>
        <img src={@image_url} />
      </div>
    """
  end

  def update(%{image_url: image_url}, socket) do
    {
      :ok,
      socket
      |> assign(:image_url, image_url)
    }
  end

end
