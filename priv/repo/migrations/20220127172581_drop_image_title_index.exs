defmodule Hexa.Repo.Migrations.DropImageTitleIndex do
  use Ecto.Migration

  def change do

    drop unique_index(:images, [:user_id, :title])
  end
end
