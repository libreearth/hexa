defmodule HexaWeb.HexaLive do
  use HexaWeb, :live_view

  alias Hexa.{MediaLibrary, ImageLibrary, Accounts}
  
  #alias HexaWeb.MapComponent
  alias HexaWeb.Endpoint
  alias HexaWeb.LayoutComponent
  alias HexaWeb.HexaLive.ImageUploadFormComponent
  alias HexaWeb.ProfileLive.ImageRowComponent

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

    <div class="px-4 mx-auto mt-6">
    <.live_phone_table
      id="images"
      module={ImageRowComponent}
      rows={@images}
      row_id={fn image -> "image-#{image.id}" end}
      owns_profile?={@owns_profile?}
    >
      <:col let={%{image: image}} label="Title"><%= image.title %></:col>
      <:col let={%{image: image}} label="URL"><.link to_out={image.image_url} target="_blank" class="inline-flex items-center px-3 py-2 text-sm leading-4 font-medium"><.icon name={:eye} class="-ml-0.5 mr-2 h-4 w-4"/>Watch</.link></:col>
      <:col let={%{image: image}} label="" if={@owns_profile?}>
        <.link phx-click={show_modal("delete-modal-#{image.id}")} class="inline-flex items-center px-3 py-2 text-sm leading-4 font-medium">
          <.icon name={:trash} class="-ml-0.5 mr-2 h-4 w-4"/>
          Delete
        </.link>
      </:col>
    </.live_phone_table>
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
        current_user: current_user,
        images: ImageLibrary.list_images(current_user.id)
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