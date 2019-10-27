defmodule Noder.Game do
  @moduledoc """
  Implement your game here
  """

  use GenServer

  def start_link(map_size) do
    GenServer.start_link(__MODULE__, map_size, name: :game)
  end

  def tick(pid) do
    GenServer.call(pid, :tick)
  end

  def update(pid, result) do
    GenServer.call(pid, {:update, result})
  end

  def init(%{rows: _rows, columns: _columns} = map_size) do
    {:ok, %{map_size: map_size}}
  end

  def handle_call(:tick, _, state) do
    response = {:rand.uniform(state.map_size.rows), :rand.uniform(state.map_size.columns)}
    {:reply, response, state}
  end

  def handle_call({:update, result}, _, state) do
    IO.inspect(result)
    # do something here
    {:reply, state, state}
  end
end
