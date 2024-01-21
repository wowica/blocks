defmodule Explorer.ChainSyncClient do
  use Xogmios, :chain_sync

  alias Explorer.Dashboard

  require Logger

  def start_link(opts) do
    Xogmios.start_chain_sync_link(__MODULE__, opts)
  end

  @impl true
  def handle_block(block, state) do
    Dashboard.broadcast_new_block(block)

    {:ok, :next_block, state}
  end
end
