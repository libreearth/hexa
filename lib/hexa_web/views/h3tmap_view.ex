defmodule HexaWeb.H3tMapView do
  use HexaWeb, :view

  def render("index.json", %{h3ts: h3ts}) do
    %{cells: render_many(h3ts, HexaWeb.H3tMapView, "h3t.json")}
  end

  def render("h3t.json", %{h3t_map: h3t}) do
    %{
      h3id: h3t.h3id,
      value: h3t.value,
      id: h3t.id
    }
  end
end