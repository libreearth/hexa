defmodule HexaWeb.HexaLive do
  use HexaWeb, :live_view

  alias Hexa.{MediaLibrary, ImageLibrary, Accounts}
  
  alias HexaWeb.MapComponent
  alias HexaWeb.Endpoint
  alias HexaWeb.LayoutComponent
  alias HexaWeb.HexaLive.ImageUploadFormComponent

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

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    if socket.assigns.owns_profile? do
      socket
      |> assign(:page_title, "Add Hexa")
      |> assign(:image, %ImageLibrary.Image{})
      |> show_upload_modal()
    else
      socket
      |> put_flash(:error, "You can't do that")
      |> redirect(to: profile_path(socket.assigns.current_user))
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Hexas")
  end

  defp show_upload_modal(socket) do
    LayoutComponent.show_modal(ImageUploadFormComponent, %{
      id: :new,
      confirm: {"Save", type: "submit", form: "image-form"},
      patch: Routes.hexa_path(Endpoint, :index, socket.assigns.current_user.username),
      image: socket.assigns.image,
      title: socket.assigns.page_title,
      current_user: socket.assigns.current_user
    })

    socket
  end
end