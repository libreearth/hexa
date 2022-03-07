defmodule Hexa.Repo.Migrations.AddH3FieldEntity do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS postgis"
    execute "CREATE EXTENSION IF NOT EXISTS h3"
    alter table(:images) do
      add :location, :h3index
    end
  end
end
