defmodule Blocks.ChainSyncClient do
  use Xogmios, :chain_sync

  alias Blocks.Dashboard

  require Logger

  def start_link(opts) do
    Xogmios.start_chain_sync_link(__MODULE__, opts)
  end

  @impl true
  def handle_block(block, state) do
    {new_block, block_to_be_removed} = Dashboard.update_blocks_db(block)
    Dashboard.broadcast_new_block(new_block, block_to_be_removed)

    {:ok, :next_block, state}
  end
end
