defmodule Noder.Client do
  use GenServer

  alias Noder.Game
  alias Noder.Games.Battleship

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :client)
  end

  def tick(pid) do
    GenServer.call(pid, :tick)
  end

  def update(pid, result) do
    GenServer.call(pid, {:update, result})
  end

  def init(_) do
    connect(Node.self())
    {:ok, game} = Game.start_link(Battleship.size())
    {:ok, %{game: game}}
  end

  def handle_call(:tick, _, state) do
    response = Game.tick(state.game)
    {:reply, response, state}
  end

  def handle_call({:update, result}, _, state) do
    Game.update(state.game, result)
    {:reply, state, state}
  end

  # def connect(:"node1@127.0.0.1") do
  def connect(:"node1@10.0.1.10") do
    IO.inspect("NOT CONNECTING")
  end

  def connect(_) do
    IO.inspect("CONNECTING")

    Node.connect(:"node1@10.0.1.10")
    |> IO.inspect()
  end
end
