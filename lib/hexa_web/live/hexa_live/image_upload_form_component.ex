defmodule HexaWeb.HexaLive.ImageUploadFormComponent do
  use HexaWeb, :live_component

  alias Hexa.ImageLibrary
  alias HexaWeb.ProfileLive.ImageEntryComponent
  alias HexaWeb.Endpoint

  @max_entries 10

  @impl true
  def update(%{image: image} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(changesets: %{}, error_messages: [])
     |> allow_upload(:image,
       image_id: image.id,
       auto_upload: true,
       progress: &handle_progress/3,
       accept: ~w(.jpg),
       max_entries: @max_entries,
       chunk_size: 64_000 * 3
     )}
  end

  @impl true
  def handle_event("validate", %{"_target" => ["image"]}, socket) do
    {_done, in_progress} = uploaded_entries(socket, :image)

    new_socket =
      Enum.reduce(in_progress, socket, fn entry, acc -> put_new_changeset(acc, entry) end)

    {:noreply, drop_invalid_uploads(new_socket)}
  end

  def handle_event("validate", %{"images" => params, "_target" => ["images", _, _]}, socket) do
    {:noreply, apply_params(socket, params, :validate)}
  end

  def handle_event("save", %{"songs" => params}, socket) do
    socket = apply_params(socket, params, :insert) 
    %{current_user: current_user} = socket.assigns
    changesets = socket.assigns.changesets

    
    case ImageLibrary.import_images(current_user, changesets, &consume_entry(socket, &1, &2)) do
      {:ok, images} ->
        {:noreply,
          socket
          |> put_flash(:info, "#{map_size(images)} images(s) uploaded")
          |> push_patch(to: Routes.hexa_path(Endpoint, :index, current_user))}

      {:error, {failed_op, reason}} ->
        {:noreply, put_error(socket, {failed_op, reason})}
    end
  end

  def handle_event("save", %{} = params, socket) do
    {:noreply, socket}
  end

  defp pending_stats?(socket) do
    Enum.find(socket.assigns.changesets, fn {_ref, chset} -> !chset.changes[:duration] end)
  end

  defp consume_entry(socket, ref, store_func) when is_function(store_func) do
    {entries, []} = uploaded_entries(socket, :image)
    entry = Enum.find(entries, fn entry -> entry.ref == ref end)
    consume_uploaded_entry(socket, entry, fn meta -> {:ok, store_func.(meta.path)} end)
  end

  defp apply_params(socket, params, action) when action in [:validate, :insert] do
    Enum.reduce(params, socket, fn {ref, image_params}, acc ->
      new_changeset =
        acc
        |> get_changeset(ref)
        |> ImageLibrary.change_image(image_params)
        |> Map.put(:action, action)

      update_changeset(acc, new_changeset, ref)
    end)
  end

  defp get_changeset(socket, entry_ref) do
    case Enum.find(socket.assigns.changesets, fn {ref, _changeset} -> ref === entry_ref end) do
      {^entry_ref, changeset} -> changeset
      nil -> nil
    end
  end

  defp put_new_changeset(socket, entry) do
    cond do
      get_changeset(socket, entry.ref) ->
        socket

      Enum.count(socket.assigns.changesets) > @max_entries ->
        socket

      true ->
        attrs = ImageLibrary.parse_file_name(entry.client_name)
        changeset = ImageLibrary.change_image(%ImageLibrary.Image{}, attrs)

        update_changeset(socket, changeset, entry.ref)
    end
  end

  defp update_changeset(socket, %Ecto.Changeset{} = changeset, entry_ref) do
    update(socket, :changesets, &Map.put(&1, entry_ref, changeset))
  end

  defp drop_changeset(socket, entry_ref) do
    update(socket, :changesets, &Map.delete(&1, entry_ref))
  end

  defp handle_progress(:image, entry, socket) do
    ImageEntryComponent.send_progress(entry)

    {:noreply, put_new_changeset(socket, entry)}
  end

  defp file_error(%{kind: :dropped} = assigns),
    do: ~H|<%= @label %>: dropped (exceeds limit of 10 files)|

  defp file_error(%{kind: :too_large} = assigns),
    do: ~H|<%= @label %>: larger than 10MB|

  defp file_error(%{kind: :not_accepted} = assigns),
    do: ~H|<%= @label %>: not a valid MP3 file|

  defp file_error(%{kind: :too_many_files} = assigns),
    do: ~H|too many files|

  defp file_error(%{kind: :songs_limit_exceeded} = assigns),
    do: ~H|You exceeded the limit of songs per account|

  defp file_error(%{kind: :invalid} = assigns),
    do: ~H|Something went wrong|

  defp file_error(%{kind: %Ecto.Changeset{}} = assigns),
    do: ~H|<%= @label %>: <%=  HexaWeb.ErrorHelpers.translate_changeset_errors(@kind) %>|

  defp file_error(%{kind: {msg, opts}} = assigns) when is_binary(msg) and is_list(opts),
    do: ~H|<%= @label %>: <%= HexaWeb.ErrorHelpers.translate_error(@kind) %>|


  defp drop_invalid_uploads(socket) do
    %{uploads: uploads} = socket.assigns

    Enum.reduce(Enum.with_index(uploads.image.entries), socket, fn {entry, i}, socket ->
      if i >= @max_entries do
        cancel_changeset_upload(socket, entry.ref, :dropped)
      else
        case upload_errors(uploads.image, entry) do
          [first | _] ->
            cancel_changeset_upload(socket, entry.ref, first)

          [] ->
            socket
        end
      end
    end)
  end

  defp cancel_changeset_upload(socket, entry_ref, reason) do
    entry = get_entry!(socket, entry_ref)

    socket
    |> cancel_upload(:image, entry.ref)
    |> drop_changeset(entry.ref)
    |> put_error({entry.client_name, reason})
  end

  defp get_entry!(socket, entry_ref) do
    Enum.find(socket.assigns.uploads.image.entries, fn entry -> entry.ref == entry_ref end) ||
      raise "no entry found for ref #{inspect(entry_ref)}"
  end

  defp put_error(socket, {label, msg}) do
    update(socket, :error_messages, &Enum.take(&1 ++ [{label, msg}], -10))
  end
end
