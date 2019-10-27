defmodule Noder.Games.Battleship do
  @moduledoc """
  Battleship Game server
  """

  use GenServer

  @cols 80
  @rows 40
  @ships 20

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :battleship)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def update(pid, board) do
    GenServer.call(pid, {:update, board})
  end

  def hit(pid, coord) do
    GenServer.call(pid, {:hit, coord})
  end

  def init(_) do
    board = []

    ships =
      0..@ships
      |> Enum.map(fn _ ->
        create_ship()
      end)

    {:ok, %{board: board, ships: ships}}
  end

  def handle_call({:hit, coord}, _, state) do
    hit =
      state
      |> ship_coords
      |> Enum.member?(coord)

    updated_ships = update_ships(coord, state.ships)
    last = was_last_ship_piece(coord, updated_ships)

    cleaned_ships =
      updated_ships
      |> Enum.reject(fn ship ->
        Enum.empty?(ship)
      end)

    new_state =
      state
      |> Map.put(:ships, cleaned_ships)

    {:reply, {hit, last}, new_state}
  end

  def handle_call({:update, board}, _, state) do
    new_state = %{state | board: board}
    {:reply, new_state, new_state}
  end

  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  defp create_ship do
    height = @rows - 2
    width = @cols - 8
    start_row = :rand.uniform(height)
    start_col = :rand.uniform(width)

    for r <- start_row..(start_row + 1), c <- start_col..(start_col + 7), do: {r, c}
  end

  defp ship_coords(state) do
    state.ships
    |> List.flatten()
  end

  defp update_ships(coords, ships) do
    ships
    |> Enum.map(fn ship ->
      ship
      |> Enum.reject(fn c ->
        c == coords
      end)
    end)
  end

  defp was_last_ship_piece(coords, ships) do
    ships
    |> Enum.map(fn ship ->
      Enum.empty?(ship)
    end)
    |> Enum.any?(fn b ->
      b == true
    end)
  end

  def size do
    %{rows: @rows, columns: @cols}
  end
end
