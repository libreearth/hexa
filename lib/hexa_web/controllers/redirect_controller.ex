defmodule HexaWeb.RedirectController do
  use HexaWeb, :controller

  import HexaWeb.UserAuth, only: [fetch_current_user: 2]

  plug :fetch_current_user

  def redirect_authenticated(conn, _) do
    if conn.assigns.current_user do
      HexaWeb.UserAuth.redirect_if_user_is_authenticated(conn, [])
    else
      redirect(conn, to: Routes.sign_in_path(conn, :index))
    end
  end
end
