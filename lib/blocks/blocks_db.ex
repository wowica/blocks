defmodule Blocks.BlocksDb do
  @moduledoc """
  This module is the in-memory database for blocks
  """

  use Agent

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    Agent.start_link(fn -> [] end, name: name)
  end

  def add_block(pid \\ __MODULE__, block) do
    Agent.update(pid, fn state ->
      new_state = [block | state]

      if length(new_state) > 10 do
        Enum.drop(new_state, -1)
      else
        new_state
      end
    end)
  end

  def get_all_blocks(pid \\ __MODULE__) do
    Agent.get(pid, & &1)
  end
end
