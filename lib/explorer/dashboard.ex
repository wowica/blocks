defmodule Explorer.Dashboard do
  alias Explorer.BlocksDb

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
    BlocksDb.get_all_blocks()
  end
end
