defmodule BlocksWeb.DashboardLive do
  use BlocksWeb, :live_view

  alias VegaLite, as: Vl

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

  defp vega_lite_ada_output_spec() do
    blocks = Dashboard.load_existing_blocks()

    Vl.new(
      title: [text: "ADA Output versus Tx Count and ADA Fees", color: "#ffffff"],
      width: 400,
      height: 200,
      padding: 5,
      color: "#fffff"
    )
    |> Vl.data_from_values(blocks)
    |> Vl.encode_field(:x, "block_height",
      type: :nominal,
      axis: [grid: false, label_color: "#94a3b8", title_color: "#ffffff"],
      title: "Block (Height)"
    )
    |> Vl.layers([
      Vl.new()
      |> Vl.mark(:bar, tooltip: true, color: "#85C5A6")
      |> Vl.encode_field(:y, "ada_output",
        type: :quantitative,
        format: ".1f",
        axis: [grid: false, ticks: false, labels: false, title_color: "#ffffff", domain: false],
        title: "ADA Output",
        color: "#ffffff"
      ),
      Vl.new()
      |> Vl.mark(:line, point: true, tooltip: true)
      |> Vl.encode_field(:y, "tx_count",
        type: :quantitative,
        axis: [grid: false, ticks: false, labels: false, title: false, domain: false],
        title: "Tx Count"
      ),
      Vl.new()
      |> Vl.mark(:line, point: true, tooltip: true)
      |> Vl.encode_field(:y, "fees",
        type: :quantitative,
        format: ".1f",
        axis: [grid: false, ticks: false, labels: false, title: false, domain: false],
        title: "ADA Fees"
      )
    ])
    |> Vl.resolve(:scale, y: :independent)
    |> Vl.config(view: [stroke: :transparent], background: :transparent)
    |> Vl.to_spec()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="block md:block relative overflow-auto">
      <div class="flex my-10">
        <div class="flex-1 bg-slate-800 shadow-md rounded-lg">
          <.live_component
            module={BlocksWeb.VegaLiteComponent}
            id="example-2"
            spec={vega_lite_ada_output_spec()}
          />
        </div>
        <div class="flex-1"></div>
      </div>

      <table class="border-collapse table-auto w-full text-xs md:text-sm">
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
              ADA Fees
            </th>
            <th class="hidden sm:block border-b border-slate-600 font-medium p-2 pt-0 pb-3 text-center">
              Date/Time (UTC)
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
            <td class="hidden sm:block border-b border-slate-100 border-slate-700 p-2 text-slate-400 text-center">
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
