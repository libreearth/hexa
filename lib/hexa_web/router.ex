defmodule HexaWeb.Router do
  use HexaWeb, :router

  import HexaWeb.UserAuth,
    only: [redirect_if_user_is_authenticated: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HexaWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", HexaWeb do
    pipe_through :api

    resources "/tiles/hexas/h3t/:z/:x/:y", H3tMapController, only: [:index]
  end

  scope "/", HexaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/oauth/callbacks/:provider", OAuthCallbackController, :new
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: HexaWeb.Telemetry
    end
  end

  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", HexaWeb do
    pipe_through :browser

    get "/", RedirectController, :redirect_authenticated
    get "/files/:id", FileController, :show

    delete "/signout", OAuthCallbackController, :sign_out

    live_session :default, on_mount: [{HexaWeb.UserAuth, :current_user}, HexaWeb.Nav] do
      live "/signin", SignInLive, :index
      live "/ar", ArLive, :index
    end

    live_session :authenticated,
      on_mount: [{HexaWeb.UserAuth, :ensure_authenticated}, HexaWeb.Nav] do
      live "/map", MapLive, :index
      live "/:profile_username/songs/new", ProfileLive, :new
      live "/:profile_username", ProfileLive, :show
      live "/:profile_username/hexa", HexaLive, :index
      live "/:profile_username/hexa/new", HexaLive, :new
      live "/profile/settings", SettingsLive, :edit
    end
  end
end
