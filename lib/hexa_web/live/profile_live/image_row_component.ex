defmodule HexaWeb.ProfileLive.ImageRowComponent do
  use HexaWeb, :live_component

  def render(assigns) do
    ~H"""
    <tr id={@id} class={@class}}>
      <%= for {col, i} <- Enum.with_index(@col) do %>
        <td
          class={"px-6 py-3 text-sm font-medium text-gray-900 #{if i == 0, do: "w-80 cursor-pointer"} #{col[:class]}"}
         >
          <div class="flex items-center space-x-3 lg:pl-2">
            <%= render_slot(col, assigns) %>
          </div>
        </td>
      <% end %>
    </tr>
    """
  end

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       id: assigns.id,
       image: assigns.row,
       col: assigns.col,
       class: assigns.class,
       index: assigns.index,
       owns_profile?: assigns.owns_profile?
     )}
  end
end
