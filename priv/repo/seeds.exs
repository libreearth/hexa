# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hexa.Repo.insert!(%Hexa.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# for title <- ~w(Chill Pop Hip-hop Electronic) do
#   {:ok, _} = Hexa.MediaLibrary.create_genre(%{title: title})
# end

# for i <- 1..200 do
#   filename = Ecto.UUID.generate()

#   {:ok, _} =
#     Hexa.Repo.insert(%Hexa.MediaLibrary.Song{
#       artist: "Bonobo",
#       title: "Black Sands #{i}",
#       duration: 180_000,
#       mp3_filename: filename,
#       mp3_path: "uploads/songs/#{filename}"
#     })
# end
