defmodule Hexa.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :title, :string, null: false
      add :image_url, :string, null: false
      add :image_filename, :string, null: false
      add :image_filepath, :string, null: false
      add :user_id, references(:users, on_delete: :nothing)
      timestamps()
    end

    create unique_index(:images, [:user_id, :title])
    create index(:images, [:user_id])
  end
end
