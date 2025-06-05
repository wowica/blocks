defmodule Blocks.ChainSyncClient do
  @moduledoc """
  This module is responsible for syncing with the chain
  and updating the dashboard with new blocks as they become available.

  Rollbacks clear the blocks from the dashboard that are older than the
  slot number of the rollback.
  """

  use Xogmios, :chain_sync

  alias Blocks.Dashboard

  require Logger

  def start_link(opts) do
    Xogmios.start_chain_sync_link(__MODULE__, opts)
  end

  @impl true
  def handle_block(block, state) do
    Dashboard.update_blocks(block)

    {:ok, :next_block, state}
  end

  @impl true
  def handle_rollback(%{slot: slot} = _point, state) do
    Dashboard.rollback_to_slot(slot)

    {:ok, :next_block, state}
  end
end
