defmodule HexaWeb.PageController do
  use HexaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
