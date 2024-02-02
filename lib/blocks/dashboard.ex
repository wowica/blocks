defmodule Blocks.Dashboard do
  alias Blocks.BlocksDb

  @pub_sub Blocks.PubSub
  @new_blocks "new-blocks"

  def subscribe() do
    Phoenix.PubSub.subscribe(@pub_sub, @new_blocks)
  end

  def broadcast_new_block(new_block, block_to_be_removed) do
    # Set this flag for animate-fadeIn
    new_block = Map.merge(new_block, %{is_real_time: true})
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
      |> Stream.filter(& &1)
      |> Enum.sum()
      |> Decimal.div(1_000_000)
      |> Decimal.round(4)
      |> to_string()

    fees =
      Stream.map(block["transactions"], fn tx ->
        tx["fee"]["lovelace"]
      end)
      |> Stream.filter(& &1)
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
      date_time: date_time_utc()
    }

    all_blocks = BlocksDb.get_all_blocks()
    # Get the @max_blocks_per_page-nth block on the db
    # so it can be removed from the table display. This might
    # be nil while BlockDb is still building up to @max_blocks_per_page
    block_to_be_removed = Enum.at(all_blocks, @max_blocks_per_page - 1)

    BlocksDb.add_block(new_block)

    {new_block, block_to_be_removed}
  end

  defp date_time_utc do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_string()
    |> String.slice(0..18)
  end
end
