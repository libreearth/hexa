defmodule Hexa.H3Utils do

  def exif_to_h3(%Exexif.Data.Gps{gps_latitude: nil, gps_latitude_ref: nil, gps_longitude: nil, gps_longitude_ref: nil}, _level) do
    nil
  end

  def exif_to_h3(%Exexif.Data.Gps{gps_latitude: [lat_g, lat_m, lat_s], gps_latitude_ref: lat_r, gps_longitude: [lon_g, lon_m, lon_s], gps_longitude_ref: lon_r}, level) do
    :h3.from_geo({to_grads(lon_r, lon_g, lon_m, lon_s), to_grads(lat_r, lat_g, lat_m, lat_s)}, level) |> Integer.to_string(16)
  end

  def exif_to_h3(_gps, _level) do
    nil
  end

  defp to_grads(r, g, m, s) when r == "S" or r =="W" do
    -(g+(m/60)+(s/3600))
  end

  defp to_grads(_r, g, m, s) do
    g+(m/60)+(s/3600)
  end
end