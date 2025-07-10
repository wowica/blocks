defmodule Blocks.Dashboard do
  alias Blocks.BlocksDb

  @pub_sub Blocks.PubSub
  @new_blocks "new-blocks"

  defmodule Block do
    @type t() :: %__MODULE__{
            block_id: String.t(),
            block_size: String.t(),
            block_height: integer(),
            block_slot: integer(),
            issuer: String.t(),
            is_real_time: boolean(),
            tx_count: integer(),
            ada_output: String.t(),
            fees: String.t(),
            date_time: String.t()
          }

    defstruct [
      :block_id,
      :block_size,
      :block_height,
      :block_slot,
      :issuer,
      :is_real_time,
      :tx_count,
      :ada_output,
      :fees,
      :date_time
    ]
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(@pub_sub, @new_blocks)
  end

  @spec load_existing_blocks() :: list()
  def load_existing_blocks do
    BlocksDb.get_all_blocks()
  end

  @doc """
  Builds the new block map, adds to the db and broadcasts the new block.
  """
  @spec update_blocks(block_from_xogmios :: map()) :: :ok
  def update_blocks(block) do
    %Block{} = new_block = build_new_block(block)

    _ = BlocksDb.add_block(new_block)
    broadcast_new_block(new_block)

    :ok
  end

  @doc """
  Rolls back the db to the given slot and broadcasts the blocks to be removed
  """
  @spec rollback_to_slot(slot_to_rollback_to :: integer()) :: :ok
  def rollback_to_slot(slot_to_rollback_to) do
    blocks_to_remove = BlocksDb.rollback_db(slot_to_rollback_to)
    broadcast_rollback(blocks_to_remove)

    :ok
  end

  defp broadcast_new_block(%Block{} = new_block) do
    # Set this flag for animate-fadeIn
    new_block = %{new_block | is_real_time: true}
    Phoenix.PubSub.broadcast(@pub_sub, @new_blocks, {:new_block, new_block})
  end

  def broadcast_rollback(blocks_to_remove) do
    Phoenix.PubSub.broadcast(@pub_sub, @new_blocks, {:rollback, blocks_to_remove})
  end

  defp build_new_block(%{"transactions" => transactions} = block) do
    ada_output =
      transactions
      |> Stream.flat_map(fn tx -> tx["outputs"] end)
      |> Stream.map(fn output -> output["value"]["ada"]["lovelace"] end)
      |> Enum.sum()
      |> Decimal.div(1_000_000)
      |> Number.Delimit.number_to_delimited(precision: 0)

    fees =
      Stream.map(transactions, fn tx ->
        tx["fee"]["ada"]["lovelace"]
      end)
      |> Enum.sum()
      |> Decimal.div(1_000_000)
      |> Decimal.round(2)
      |> to_string()

    %Block{
      block_id: block["id"],
      block_size: Decimal.div(block["size"]["bytes"], 1000) |> Decimal.round(1) |> to_string,
      block_height: block["height"],
      block_slot: block["slot"],
      issuer: block["issuer"],
      tx_count: Enum.count(transactions),
      ada_output: ada_output,
      fees: fees,
      date_time: date_time_utc()
    }
  end

  defp date_time_utc do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_string()
    |> String.slice(0..18)
  end
end
