Postgrex.Types.define(
  Hexa.PostgresTypes,
  [Geo.PostGIS.Extension] ++ [H3.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
