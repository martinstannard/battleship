defmodule Noder.Server do
  use GenServer
  alias Noder.Games.Battleship

  @tick_ms 30

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :server)
  end

  def init(_) do
    IO.inspect(Node.self())
    start_server(Node.self())
    {:ok, pid} = Battleship.start_link(nil)

    {:ok, %{pid: pid}}
  end

  def handle_info(:tick, state) do
    IO.inspect("tick")
    board = Battleship.state(state.pid).board
    dump(board)
    {responses, _} = GenServer.multi_call(Node.list(), :client, {:tick, board})

    new_board =
      responses
      |> Enum.reduce(board, fn {_, coords}, acc ->
        acc
        |> Battleship.bomb(coords)
      end)

    Battleship.update(state.pid, new_board)

    Process.send_after(self(), :tick, @tick_ms)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def start_server(:"node1@127.0.0.1") do
    Process.send_after(self(), :tick, @tick_ms)
    IO.inspect("SERVER STARTING")
  end

  def start_server(_), do: nil

  defp dump(board) do
    board
    |> Enum.each(fn row ->
      IO.puts(Enum.join(row))
    end)
  end
end
