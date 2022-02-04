defmodule HexaWeb.HexaLive do
  use HexaWeb, :live_view

  alias Hexa.{MediaLibrary, Accounts}
  
  alias HexaWeb.MapComponent
  alias HexaWeb.Endpoint

  def render(assigns) do
    ~H"""
    <.title_bar>
      User's Hexas
      <:actions>
        <%= if @owns_profile? do %>
          <.button id="upload-btn" primary patch={Routes.hexa_path(Endpoint, :new, @current_user.username)}>
            <.icon name={:upload}/><span class="ml-2">Upload Hexas</span>
          </.button>
        <% end %>
      </:actions>
    </.title_bar>

    <div class="max-w-3xl px-4 mx-auto mt-6">
      Here goes a list of hexas
    </div>
    """
  end
    
  def mount(%{"profile_username" => profile_username}, _session, socket) do
    %{current_user: current_user} = socket.assigns
    profile =
      Accounts.get_user_by!(username: profile_username)
      |> MediaLibrary.get_profile!()
    {
      :ok, 
      assign(
        socket, 
        owns_profile?: MediaLibrary.owns_profile?(current_user, profile),
        current_user: current_user
      )
    }
  end
end