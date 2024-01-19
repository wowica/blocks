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
  def handle_info({:new_block, block}, socket) do
    ada_output =
      block["transactions"]
      |> Stream.flat_map(fn tx -> tx["outputs"] end)
      |> Stream.map(fn output -> output["value"]["ada"]["lovelace"] end)
      |> Enum.sum()
      |> Decimal.div(1_000_000)
      |> Decimal.round(4)
      |> to_string()

    fees =
      Stream.map(block["transactions"], fn tx ->
        tx["fee"]["lovelace"]
      end)
      |> Enum.sum()
      |> Decimal.div(1_000_000)
      |> Decimal.round(4)
      |> to_string()

    new_block = %{
      block_id: block["id"],
      block_size: block["size"]["bytes"],
      block_height: block["height"],
      issuer: block["issuer"],
      tx_count: Enum.count(block["transactions"]),
      ada_output: ada_output,
      fees: fees
    }

    send(self(), :reset_counter)

    IO.puts("new block")

    new_socket = stream_insert(socket, :blocks, new_block, at: 0)
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
      <h2 class="inline-block text-2xl sm:text-3xl font-extrabold tracking-tight dark:text-slate-200 mb-10">
        Latest Blocks
      </h2>

      <div class="ml-auto flex flex-col">
        <span class="inline-block sm:text-lg font-extrabold tracking-tight dark:text-slate-200 w-max">
          Last updated
        </span>
        <span phx-hook="timer" id="timer-1" class="last-updated sm:text-sml dark:text-slate-200">
          0 seconds ago
        </span>
      </div>
    </div>

    <div class="hidden md:block relative rounded-xl overflow-auto">
      <table class="border-collapse table-auto w-full text-sm">
        <thead>
          <tr>
            <th class="border-b dark:border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Block (Height)
            </th>
            <th class="border-b dark:border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              ID
            </th>
            <th class="border-b dark:border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Size
            </th>
            <th class="border-b dark:border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Tx Count
            </th>
            <th class="border-b dark:border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              ADA Output
            </th>
            <th class="border-b dark:border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Fees
            </th>
          </tr>
        </thead>
        <tbody id="blocks" phx-update="stream">
          <tr
            :for={{dom_id, block} <- assigns.streams.blocks}
            id={dom_id}
            class="dark:bg-slate-800 hover:bg-slate-700 animate-fadeIn"
          >
            <td class="border-b border-slate-100 dark:border-slate-700 p-2 dark:text-slate-400 text-center">
              <%= block.block_height %>
            </td>
            <td class="border-b border-slate-100 dark:border-slate-700 p-2 dark:text-slate-400 text-center">
              <%= String.slice(block.block_id, 0..7) %>
            </td>
            <td class="border-b border-slate-100 dark:border-slate-700 p-2 dark:text-slate-400 text-center">
              <%= block.block_size %>
            </td>
            <td class="border-b border-slate-100 dark:border-slate-700 p-2 dark:text-slate-400 text-center">
              <%= block.tx_count %>
            </td>
            <td class="border-b border-slate-100 dark:border-slate-700 p-2 dark:text-slate-400 text-center">
              <%= block.ada_output %>
            </td>
            <td class="border-b border-slate-100 dark:border-slate-700 p-2 dark:text-slate-400 text-center">
              <%= block.fees %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
