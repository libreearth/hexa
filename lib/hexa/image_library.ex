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

  def list_h3_tile(x,y,z, z_h3) do
    {lat_up, lon_up} = get_lat_lng_for_number(x,y,z)
    {lat_dw, lon_dw} = get_lat_lng_for_number(x+1, y+1, z)
    wkt = to_wkt(lat_up, lon_up, lat_dw, lon_dw)
    h3_query(wkt, z_h3, abs(lon_up-lon_dw)/4)
    |> Map.get(:rows)
  end

  defp h3_query(wkt, z_h3, buffer) do
    query = 
      if z_h3 <= Image.data_level()  do
        """
          select im as location, image_url from h3_polyfill(st_buffer(st_GeometryFromText('#{wkt}'),#{buffer}),#{z_h3}) as im 
          left join images on images.location in (select h3_to_children(im, #{Image.data_level()}))
        """
      else
        """
          select im as location, image_url from h3_polyfill(st_buffer(st_GeometryFromText('#{wkt}'),#{buffer}),#{z_h3}) as im 
          left join images on images.location in (select h3_to_parent(im, #{Image.data_level()}))
        """
      end
    {:ok, result} = Ecto.Adapters.SQL.query(Repo.replica(), query)
    result
  end

  defp h3_query_inner(wkt, z_h3, buffer) do
    query = 
      if z_h3 <= Image.data_level()  do
        """
          select im as location, image_url from h3_polyfill(st_buffer(st_GeometryFromText('#{wkt}'),#{buffer}),#{z_h3}) as im 
          inner join images on images.location in (select h3_to_children(im, #{Image.data_level()}))
        """
      else
        """
          select im as location, image_url from h3_polyfill(st_buffer(st_GeometryFromText('#{wkt}'),#{buffer}),#{z_h3}) as im 
          inner join images on images.location in (select h3_to_parent(im, #{Image.data_level()}))
        """
      end
    {:ok, result} = Ecto.Adapters.SQL.query(Repo.replica(), query)
    result
  end

  def get_lat_lng_for_number(xtile, ytile, zoom) do
    n = Math.pow(2.0, zoom)
    lon_deg = xtile / n * 360.0 - 180.0
    lat_rad = Math.atan(Math.sinh(Math.pi * (1 - 2 * ytile / n)))
    lat_deg = 180.0 * (lat_rad / Math.pi)
    {lat_deg, lon_deg}
  end

  def to_wkt(lat_up, lon_up, lat_dw, lon_dw) do
    "POLYGON((#{lon_up} #{lat_up}, #{lon_dw} #{lat_up}, #{lon_dw} #{lat_dw}, #{lon_up} #{lat_dw}, #{lon_up} #{lat_up}))"
  end

  def list_images() do
    Repo.replica().all(from i in Image)
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