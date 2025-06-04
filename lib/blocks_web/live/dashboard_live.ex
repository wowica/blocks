defmodule BlocksWeb.DashboardLive do
  use BlocksWeb, :live_view

  alias Blocks.Dashboard

  @table_limit 10

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
  def handle_info({:new_block, new_block}, socket) do
    send(self(), :reset_counter)

    new_socket = stream_insert(socket, :blocks, new_block, at: 0, limit: @table_limit)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:reset_counter, socket) do
    {:noreply, push_event(socket, "resetCounter", %{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="block md:block relative overflow-auto max-w-[95vw] md:max-w-[90vw] lg:max-w-[85vw] mx-auto">
      <table class="border-collapse table-auto w-full min-w-[800px] md:min-w-[1000px] lg:min-w-[1200px]">
        <thead>
          <tr>
            <th class="border-b border-slate-600 text-[10px] font-normal sm:text-sm md:text-base md:font-medium p-2 pt-0 pb-3 text-center">
              Height
            </th>
            <th class="border-b border-slate-600 text-[10px] font-normal sm:text-sm md:text-base md:font-medium p-2 pt-0 pb-3 text-center">
              Block Hash
            </th>
            <th class="border-b border-slate-600 text-[10px] font-normal sm:text-sm md:text-base md:font-medium p-2 pt-0 pb-3 text-center">
              Slot
            </th>
            <th class="border-b border-slate-600 text-[10px] font-normal sm:text-sm md:text-base md:font-medium p-2 pt-0 pb-3 text-center">
              Size (kb)
            </th>
            <th class="border-b border-slate-600 text-[10px] font-normal sm:text-sm md:text-base md:font-medium p-2 pt-0 pb-3 text-center">
              Tx Count
            </th>
            <th class="border-b border-slate-600 text-[10px] font-normal sm:text-sm md:text-base md:font-medium p-2 pt-0 pb-3 text-center">
              ADA Output / Fees
            </th>
            <th class="border-b border-slate-600 text-[10px] font-normal sm:text-sm md:text-base md:font-medium p-2 pt-0 pb-3 text-center">
              Date / Time (UTC)
            </th>
          </tr>
        </thead>
        <tbody id="blocks" phx-update="stream">
          <tr
            :for={{dom_id, block} <- assigns.streams.blocks}
            id={dom_id}
            class={[
              "bg-slate-800 hover:bg-slate-700",
              if(block[:is_real_time], do: "animate-fadeIn")
            ]}
          >
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center sm:text-sm md:text-base md:font-medium">
              <%= block.block_height %>
            </td>

            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center sm:text-sm md:text-base md:font-medium">
              <span class="text-[11px] text-slate-400">
                <%= String.slice(block.block_id, 0, 6) <>
                  "..." <> String.slice(block.block_id, -6, 6) %>
                <Heroicons.clipboard_document_list
                  class="inline-block w-4 h-4 ml-1 cursor-pointer hover:text-slate-300"
                  phx-hook="clipboard"
                  id={"clipboard-#{block.block_id}"}
                  data-clipboard-text={block.block_id}
                />
              </span>
            </td>

            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center sm:text-sm md:text-base md:font-medium">
              <%= block.block_slot %>
            </td>
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center sm:text-sm md:text-base md:font-medium">
              <%= block.block_size %>
            </td>
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center sm:text-sm md:text-base md:font-medium">
              <%= block.tx_count %>
            </td>
            <td class="border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center sm:text-sm md:text-base md:font-medium">
              <%= block.ada_output %> / <%= block.fees %>
            </td>
            <td class="border-b border-slate-100 border-slate-700 p-3 text-slate-400 text-center sm:text-sm md:text-base md:font-medium">
              <%= block.date_time %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="flex flex-row items-center justify-center mt-5 text-sm">
      <div class="mt-2 flex flex-col items-center">
        <span class="sm:text-sm md:text-lg font-bold tracking-tight text-slate-300 w-max">
          Last updated
        </span>
        <span phx-hook="timer" id="timer-1" class="last-updated text-sml text-slate-300">
          0 seconds ago
        </span>
      </div>
    </div>
    """
  end
end
