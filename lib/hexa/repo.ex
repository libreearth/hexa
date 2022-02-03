defmodule Hexa.Repo do
  use Ecto.Repo,
    otp_app: :hexa,
    adapter: Ecto.Adapters.Postgres

  def replica, do: Hexa.config([:replica])
end

defmodule Hexa.ReplicaRepo do
  use Ecto.Repo,
    otp_app: :hexa,
    adapter: Ecto.Adapters.Postgres
end
