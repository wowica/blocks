defmodule Blocks.Dashboard do
  alias Blocks.BlocksDb

  @pub_sub Blocks.PubSub
  @new_blocks "new-blocks"

  def subscribe() do
    Phoenix.PubSub.subscribe(@pub_sub, @new_blocks)
  end

  def broadcast_new_block(new_block) do
    # Set this flag for animate-fadeIn
    new_block = Map.merge(new_block, %{is_real_time: true})
    Phoenix.PubSub.broadcast(@pub_sub, @new_blocks, {:new_block, new_block})
  end

  @spec load_existing_blocks() :: list()
  def load_existing_blocks do
    BlocksDb.get_all_blocks()
  end

  @type new_block :: map()
  @type block_to_be_removed :: map()

  @doc """
  Builds the block map, adds to the db and invokes callback with the new block.
  """
  @spec update_blocks_db(block_from_xogmios :: map(), callback :: fun()) :: :ok
  def update_blocks_db(block, callback) do
    ada_output =
      block["transactions"]
      |> Stream.flat_map(fn tx -> tx["outputs"] end)
      |> Stream.map(fn output -> output["value"]["ada"]["lovelace"] end)
      |> Enum.sum()
      |> Decimal.div(1_000_000)
      |> Number.Delimit.number_to_delimited(precision: 0)

    fees =
      Stream.map(block["transactions"], fn tx ->
        tx["fee"]["ada"]["lovelace"]
      end)
      |> Enum.sum()
      |> Decimal.div(1_000_000)
      |> Decimal.round(2)
      |> to_string()

    new_block = %{
      block_id: block["id"],
      block_size: Decimal.div(block["size"]["bytes"], 1000) |> Decimal.round(1) |> to_string,
      block_height: block["height"],
      block_slot: block["slot"],
      issuer: block["issuer"],
      tx_count: Enum.count(block["transactions"]),
      ada_output: ada_output,
      fees: fees,
      date_time: date_time_utc()
    }

    IO.inspect(new_block, label: "NEW BLOCK")

    _ = BlocksDb.add_block(new_block)
    callback.(new_block)

    :ok
  end

  defp date_time_utc do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_string()
    |> String.slice(0..18)
  end
end
