defmodule Noder.Games.Battleship do
  @moduledoc """
  Battleship Game server
  """

  use GenServer

  @cols 80
  @rows 20

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :battleship)
  end

  def init(_) do
    board =
      "~"
      |> List.duplicate(@cols)
      |> List.duplicate(@rows)

    ships =
      0..5
      |> Enum.map(fn _ ->
        create_ship()
      end)

    {:ok, %{board: board, ships: ships}}
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def update(pid, board) do
    GenServer.call(pid, {:update, board})
  end

  def handle_call({:update, board}, _, _state) do
    {:reply, board, board}
  end

  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  def bomb(state, {r, c}) do
    replace_at_with(state, {r, c}, "X")
  end

  def replace_at_with(state, {r, c}, character) do
    row = Enum.at(state, r)

    new_row =
      row
      |> List.replace_at(c, character)

    new_state =
      state
      |> List.replace_at(r, new_row)

    new_state
  end

  defp create_ship do
    height = @rows - 2
    width = @cols - 8
    start_row = :rand.uniform(height)
    start_col = :rand.uniform(width)

    for r <- start_row..(start_row + 1), c <- start_col..(start_col + 7), do: {r, c}
  end
end
