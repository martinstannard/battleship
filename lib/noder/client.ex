defmodule Noder.Client do
  use GenServer

  alias Noder.Game

  def start_link(val \\ 0) do
    GenServer.start_link(__MODULE__, val, name: :client)
  end

  def init(_) do
    connect(Node.self())
    {:ok, 0}
  end

  def handle_call({:tick, world_state}, _, state) do
    # IO.inspect(state, label: :state)
    # IO.inspect(world_state, label: :world_state)
    response = Game.call(world_state)
    IO.inspect(response, label: :response)
    {:reply, response, state}
  end

  def connect(:"node1@127.0.0.1") do
    IO.inspect("NOT CONNECTING")
  end

  def connect(_) do
    IO.inspect("CONNECTING")
    Node.connect(:"node1@127.0.0.1")
  end
end
