defmodule Hexa.ImageLibrary do
  @moduledoc """
  The ImageLibrary context.
  """

  require Logger
  import Ecto.Query, warn: false

  alias Hexa.ImageLibrary.Image
  alias Hexa.Accounts
  alias Hexa.Repo


  def change_image(image_or_changeset, attrs \\ %{})

  def change_image(%Image{} = image, attrs) do
    Image.changeset(image, attrs)
  end

  @keep_changes [:image_filesize, :image_filepath, :location]
  def change_image(%Ecto.Changeset{} = prev_changeset, attrs) do
    %Image{}
    |> change_image(attrs)
    |> Ecto.Changeset.change(Map.take(prev_changeset.changes, @keep_changes))
  end

  def import_images(%Accounts.User{} = user, changesets, consume_file) when is_map(changesets) and is_function(consume_file, 2) do
    # refetch user for fresh image count
    user = Accounts.get_user!(user.id)

    multi =
      Enum.reduce(changesets, Ecto.Multi.new(), fn {ref, chset}, acc ->
        chset =
          chset
          |> Image.put_user(user)
          |> Image.put_image_path()

        Ecto.Multi.insert(acc, {:image, ref}, chset)
      end)

    case Hexa.Repo.transaction(multi) do
      {:ok, results} ->
        images =
          results
          |> Enum.filter(&match?({{:image, _ref}, _}, &1))
          |> Enum.map(fn {{:image, ref}, image} ->
            consume_file.(ref, fn tmp_path -> store_image(image, tmp_path) end)
            {ref, image}
          end)

        broadcast_imported(user, images)

        {:ok, Enum.into(images, %{})}

      {:error, failed_op, failed_val, _changes} ->
        failed_op =
          case failed_op do
            {:image, _number} -> "Invalid image (#{failed_val.changes.title})"
            failed_op -> failed_op
          end

        {:error, {failed_op, failed_val}}
    end
  end

  def list_images(user_id) do
    query = from( i in Image, where: i.user_id == ^user_id, order_by: [asc: :title])
    Repo.replica().all(query)
  end

  def store_image(%Image{} = image, tmp_path) do
    File.mkdir_p!(Path.dirname(image.image_filepath))
    File.cp!(tmp_path, image.image_filepath)
  end

  defp broadcast_imported(%Accounts.User{} = _user, images) do
    _images = Enum.map(images, fn {_ref, image} -> image end)
    #broadcast!(user.id, %Events.SongsImported{user_id: user.id, songs: songs})
  end

  def parse_file_name(name) do
    %{title: Path.rootname(name)}
  end

end