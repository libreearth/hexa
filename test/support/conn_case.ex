defmodule HexaWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use HexaWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  @endpoint HexaWeb.Endpoint
  import Phoenix.ConnTest

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import HexaWeb.ConnCase
      import unquote(__MODULE__)

      alias HexaWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint HexaWeb.Endpoint
    end
  end

  defp wait_for_children(children_lookup) when is_function(children_lookup) do
    Process.sleep(100)

    for pid <- children_lookup.() do
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}, 1000
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Hexa.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    on_exit(fn ->
      wait_for_children(fn -> HexaWeb.Presence.fetchers_pids() end)
    end)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def log_in_user(conn, user) do
    conn
    |> Phoenix.ConnTest.bypass_through(HexaWeb.Router, [:browser])
    |> get("/")
    |> HexaWeb.UserAuth.log_in_user(user)
    |> Phoenix.ConnTest.recycle()
  end
end
