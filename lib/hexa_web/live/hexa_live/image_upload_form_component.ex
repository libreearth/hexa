defmodule HexaWeb.HexaLive.ImageUploadFormComponent do
  use HexaWeb, :live_component

  alias Hexa.ImageLibrary
  alias Hexa.ImageLibrary.Image
  alias HexaWeb.ProfileLive.ImageEntryComponent

  @max_entries 10

  @impl true
  def update(%{action: {:location, entry_ref}}, socket) do
    phone_location = Map.get(socket.assigns, :location, nil)
    clicked_coord = Map.get(socket.assigns, :clicked_coord, nil)
    case (clicked_coord || phone_location)  do
      %{"lat" => _lat, "lon" => _lon} = location -> {:ok, put_gps_data(socket, entry_ref, location)}
      _ -> {:ok, cancel_changeset_upload(socket, entry_ref, :not_geolocated)}
    end
  end

  def update(%{image: image} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(changesets: %{}, error_messages: [])
     |> allow_upload(:image,
       image_id: image.id,
       auto_upload: true,
       progress: &handle_progress/3,
       accept: ~w(.jpg .jpeg),
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

  def handle_event("validate", %{"songs" => params, "_target" => ["songs", _, _]}, socket) do
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
          |> push_patch(to: socket.assigns.patch)}#Routes.hexa_path(Endpoint, :index, current_user.username))}

      {:error, {failed_op, reason}} ->
        {:noreply, put_error(socket, {failed_op, reason})}
    end
  end

  def handle_event("save", %{} = _params, socket) do
    {:noreply, socket}
  end

  def handle_event("location-avaliable", location, socket) do
    {:noreply, assign(socket, :location, location)}
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

    if entry.done? do
      async_calculate_duration(socket, entry)
    end

    {:noreply, put_new_changeset(socket, entry)}
  end

  defp async_calculate_duration(socket, %Phoenix.LiveView.UploadEntry{} = entry) do
    lv = self()

    consume_uploaded_entry(socket, entry, fn %{path: path} ->
      Task.Supervisor.start_child(Hexa.TaskSupervisor, fn ->
        send_update(lv, __MODULE__,
          id: socket.assigns.id,
          action: {:location, entry.ref}
        )
      end)

      {:postpone, :ok}
    end)
  end

  defp put_gps_data(socket, entry_ref, gps_data) do
    if changeset = get_changeset(socket, entry_ref) do
      new_changeset = Image.put_gps_data(changeset, gps_data)
      update_changeset(socket, new_changeset, entry_ref)
    else
      socket
    end
  end

  defp file_error(%{kind: :dropped} = assigns),
    do: ~H|<%= @label %>: dropped (exceeds limit of 10 files)|

  defp file_error(%{kind: :not_accepted} = assigns),
    do: ~H|<%= @label %>: not a valid JPG file.|

  defp file_error(%{kind: :not_geolocated} = assigns),
    do: ~H|<%= @label %>: The image must be geolocated or phone location must be on.|

  defp file_error(%{kind: :too_many_files} = assigns),
    do: ~H|too many files|

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
