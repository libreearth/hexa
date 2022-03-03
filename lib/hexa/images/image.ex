defmodule Hexa.ImageLibrary.Image do
  use Ecto.Schema
  import Ecto.Changeset

  alias Hexa.ImageLibrary.Image
  alias Hexa.Accounts

  schema "images" do
    field :title, :string
    field :image_url, :string
    field :image_filepath, :string
    field :image_filename, :string
    belongs_to :user, Accounts.User

    timestamps()
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
