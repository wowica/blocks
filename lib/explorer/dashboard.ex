defmodule Explorer.Dashboard do
  @pub_sub Explorer.PubSub
  @new_blocks "new-blocks"

  def subscribe() do
    Phoenix.PubSub.subscribe(@pub_sub, @new_blocks)
  end

  def broadcast_new_block(block) do
    Phoenix.PubSub.broadcast(@pub_sub, @new_blocks, {:new_block, block})
  end

  @spec load_existing_blocks() :: list()
  def load_existing_blocks do
    # TODO: replace with real data
    [
      %{
        block_id: "123123",
        block_height: "123123",
        ada_output: "123123",
        fees: "123123",
        block_size: "92992",
        tx_count: 123
      },
      %{
        block_id: "123124",
        block_height: "123123",
        ada_output: "123123",
        fees: "123123",
        block_size: "92992",
        tx_count: 123
      },
      %{
        block_id: "123125",
        block_height: "123123",
        ada_output: "123123",
        fees: "123123",
        block_size: "92992",
        tx_count: 123
      },
      %{
        block_id: "123126",
        block_height: "123123",
        ada_output: "123123",
        fees: "123123",
        block_size: "92992",
        tx_count: 123
      }
    ]
  end
end
