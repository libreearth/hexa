defmodule HexaWeb.ArComponent do
  use HexaWeb, :live_component

  def render(assigns) do
    ~H"""
      <div id="ar-frame" phx-hook="Ar">
        <a-scene embedded vr-mode-ui="enabled: false"
        arjs="sourceType: webcam; videoTexture: true; debugUIEnabled: false;">
          <a-camera gps-camera="alert: true; positionMinAccuracy : 10;" rotation-reader/>
          <a-box gps-entity-place="latitude: 37.3473279; longitude: -5.9735585;"
            color="#4CC3D9"
            position="0 0 0"/>

          <a-box gps-entity-place="latitude: 39.136634; longitude: -6.842715;"
            color="#4CC3D9"
            position="0 0 0"/>

          <a-box gps-entity-place="latitude: 37.331830; longitude: -5.9667812;"
            color="#4CC3D9"
            position="0 0 0"/>
        </a-scene>
      </div>
    """
  end
end
