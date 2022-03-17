defmodule HexaWeb.H3tMapController do
  use HexaWeb, :controller

  alias Hexa.ImageLibrary

  @zooms %{
    "5" => 3,
    "6" => 4,
    "7" => 5,
    "8" => 5,
    "9" => 6,
    "10" => 7,
    "11" => 8,
    "12" => 8,
    "13" => 9,
    "14" => 9,
    "15" => 11,
    "16" => 12,
    "17" => 13,
    "18" => 14,
    "19" => 15,
    "20" => 15,
    "21" => 15,
    "22" => 15,
    "23" => 15,
    "24" => 15
  }
  
  def index(conn, %{"z" => zs, "x" => xs, "y" => ys}) do
    x = String.to_integer(xs)
    y = String.to_integer(ys)
    z = String.to_integer(zs)
    zh3 = to_h3_zoom(zs)


    h3ts = ImageLibrary.list_h3_tile(x, y, z, zh3)
    |> Enum.map(& to_h3t(&1))
    render(conn, "index.json", h3ts: h3ts)
  end

  defp to_h3_zoom(zoom) do
    Map.get(@zooms, zoom, nil)
  end


  defp to_h3t(%Hexa.ImageLibrary.Image{} = image) do
    %{id: image.id, h3id: image.location, value: 5}
  end

  defp to_h3t([h3, image_url]) do
    %{ id: String.to_integer(h3, 16), h3id: h3, has_image: has_image(image_url), image_url: image_url }
  end

  defp has_image(nil) do
    0
  end

  defp has_image(_image_url) do
    1
  end


end