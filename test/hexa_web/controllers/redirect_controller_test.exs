defmodule HexaWeb.RedirectControllerTest do
  use HexaWeb.ConnCase
  import Hexa.AccountsFixtures

  test "GET / redirects to signin when not logged in", %{conn: conn} do
    conn = get(conn, "/")
    assert redirected_to(conn, 302) =~ Routes.sign_in_path(conn, :index)
  end

  test "GET / redirects to profile page when signed in", %{conn: conn} do
    user = user_fixture(%{"login" => "chrismccord"})

    conn =
      conn
      |> log_in_user(user)
      |> get("/")

    assert redirected_to(conn, 302) =~ "/chrismccord"

    conn =
      conn
      |> recycle()
      |> get("/chrismccord")

    assert html_response(conn, 200) =~ "chrismccord&#39;s beats"
  end
end
