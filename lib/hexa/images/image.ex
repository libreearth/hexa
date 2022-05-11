defmodule Hexa.ImageLibrary.Image do
  use Ecto.Schema
  import Ecto.Changeset

  @h3_level Application.get_env(:hexa, :h3_level)

  alias Hexa.Accounts
  alias Hexa.H3Utils

  schema "images" do
    field :title, :string
    field :image_url, :string
    field :image_filepath, :string
    field :image_filename, :string
    field :location, H3.PostGIS.H3Index
    belongs_to :user, Accounts.User

    timestamps()
  end

  def data_level() do
    @h3_level
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> unique_constraint(:title,
      message: "is a duplicated from another image",
      name: "images_user_id_title_artist_index"
    )
  end

  def put_user(%Ecto.Changeset{} = changeset, %Accounts.User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_gps_data(%Ecto.Changeset{} = changeset, %Exexif.Data.Gps{} = gps_data) do
    Ecto.Changeset.put_change(changeset, :location, H3Utils.exif_to_h3(gps_data, @h3_level))
  end

  def put_gps_data(%Ecto.Changeset{} = changeset, %{"lat" => _lat, "lon" => _lon} = gps_data) do
    Ecto.Changeset.put_change(changeset, :location, H3Utils.latlon_to_h3(gps_data, @h3_level))
  end

  def put_image_path(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      filename = Ecto.UUID.generate() <> ".jpg"
      filepath = Hexa.MediaLibrary.local_filepath(filename)

      changeset
      |> Ecto.Changeset.put_change(:image_filename, filename)
      |> Ecto.Changeset.put_change(:image_filepath, filepath)
      |> Ecto.Changeset.put_change(:image_url, image_url(filename))
    else
      changeset
    end
  end

  defp image_url(filename) do
    %{scheme: scheme, host: host, port: port} = Enum.into(Hexa.config([:files, :host]), %{})
    URI.to_string(%URI{scheme: scheme, host: host, port: port, path: "/files/#{filename}"})
  end
end
