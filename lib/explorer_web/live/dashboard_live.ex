defmodule ExplorerWeb.DashboardLive do
  use ExplorerWeb, :live_view

  alias Explorer.Dashboard

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Dashboard.subscribe()
    end

    blocks = Dashboard.load_existing_blocks()

    new_socket =
      stream_configure(
        socket,
        :blocks,
        dom_id: &"#{&1.block_id}"
      )
      |> stream(:blocks, blocks)

    {:ok, new_socket}
  end

  @impl true
  def handle_info({:new_block, new_block, block_to_be_removed}, socket) do
    send(self(), :reset_counter)

    new_socket =
      socket
      |> stream_insert(:blocks, new_block, at: 0)
      |> then(fn socket ->
        if block_to_be_removed do
          stream_delete_by_dom_id(socket, :blocks, block_to_be_removed.block_id)
        else
          socket
        end
      end)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:reset_counter, socket) do
    {:noreply, push_event(socket, "resetCounter", %{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="hidden md:block md:flex items-center justify-between py-3 text-sm">
      <h2 class="inline-block text-2xl sm:text-3xl font-extrabold tracking-tight text-slate-200 mb-10">
        Latest Blocks
      </h2>

      <div class="ml-auto flex flex-col">
        <span class="inline-block sm:text-lg font-extrabold tracking-tight text-slate-200 w-max">
          Last updated
        </span>
        <span phx-hook="timer" id="timer-1" class="last-updated sm:text-sml text-slate-200">
          0 seconds ago
        </span>
      </div>
    </div>

    <div class="hidden md:block relative rounded-xl overflow-auto">
      <table class="border-collapse table-auto w-full text-sm">
        <thead>
          <tr>
            <th class="border-b border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Block (Height)
            </th>
            <th class="border-b border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Size (Kb)
            </th>
            <th class="border-b border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Tx Count
            </th>
            <th class="border-b border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              ADA Output
            </th>
            <th class="border-b border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Fees
            </th>
          </tr>
        </thead>
        <tbody id="blocks" phx-update="stream">
          <tr
            :for={{dom_id, block} <- assigns.streams.blocks}
            id={dom_id}
            class="bg-slate-800 hover:bg-slate-700 animate-fadeIn"
          >
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center">
              <%= block.block_height %>
            </td>
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center">
              <%= block.block_size %>
            </td>
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center">
              <%= block.tx_count %>
            </td>
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center">
              <%= block.ada_output %>
            </td>
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center">
              <%= block.fees %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
