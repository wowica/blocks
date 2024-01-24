defmodule Explorer.Dashboard do
  alias Explorer.BlocksDb

  @pub_sub Explorer.PubSub
  @new_blocks "new-blocks"

  def subscribe() do
    Phoenix.PubSub.subscribe(@pub_sub, @new_blocks)
  end

  def broadcast_new_block(new_block, block_to_be_removed) do
    Phoenix.PubSub.broadcast(@pub_sub, @new_blocks, {:new_block, new_block, block_to_be_removed})
  end

  @spec load_existing_blocks() :: list()
  def load_existing_blocks do
    BlocksDb.get_all_blocks()
  end

  @type new_block :: map()
  @type block_to_be_removed :: map()

  @max_blocks_per_page 10

  @spec update_blocks_db(block_from_xogmios :: map()) :: {new_block, block_to_be_removed}
  def update_blocks_db(block) do
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
      block_size: Decimal.div(block["size"]["bytes"], 1000) |> Decimal.round(1) |> to_string,
      block_height: block["height"],
      issuer: block["issuer"],
      tx_count: Enum.count(block["transactions"]),
      ada_output: ada_output,
      fees: fees,
      date_time: time_now_utc(),
      is_real_time: true
    }

    all_blocks = BlocksDb.get_all_blocks()
    # First, get the oldest / @max_blocks_per_page-nth block on the db
    block_to_be_removed = Enum.at(all_blocks, @max_blocks_per_page - 1)

    BlocksDb.add_block(new_block)

    {new_block, block_to_be_removed}
  end

  defp time_now_utc do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_string()
    |> String.slice(0..18)
  end
end
