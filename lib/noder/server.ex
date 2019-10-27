defmodule Noder.Server do
  use GenServer
  alias Noder.Games.Battleship

  @tick_ms 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :server)
  end

  def init(_) do
    start_server(Node.self())
    {:ok, pid} = Battleship.start_link(nil)

    {:ok, %{pid: pid, clients: %{}}}
  end

  def handle_info(:tick, state) do
    IO.inspect("tick")
    bs = Battleship.state(state.pid)
    # {responses, _} = GenServer.multi_call(Node.list(), :client, {:tick, board})

    state = update_clients(state)
    IO.inspect(state)
    responses = call_clients(state)

    new_board =
      responses
      |> Enum.reduce(bs.board, fn {_, coords}, acc ->
        acc
        |> Battleship.bomb(coords)
      end)

    state = handle_responses(responses, state)

    Battleship.update(state.pid, new_board)

    dump(state)
    Process.send_after(self(), :tick, @tick_ms)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp call_clients(state) do
    bs = Battleship.state(state.pid)
    board = bs.board
    clients = Node.list()

    clients
    |> Enum.map(fn client ->
      coords = GenServer.call({:client, client}, {:tick, board})
      {client, coords}
    end)
    |> IO.inspect()
  end

  defp update_clients(state) do
    state
    |> Map.put(:clients, new_clients(state.clients))
  end

  defp new_clients(clients) do
    Node.list()
    |> Enum.reduce(clients, fn node, acc ->
      Map.put_new(acc, node, %{hits: [], misses: []})
    end)
  end

  defp dump(state) do
    bs = Battleship.state(state.pid)
    ship_positions = List.flatten(bs.ships)
    all_hits = all_hits(state.clients)
    all_misses = all_misses(state.clients)

    0..20
    |> Enum.each(fn col ->
      0..80
      |> Enum.each(fn row ->
        write({col, row}, ship_positions, all_hits, all_misses)
        # IO.puts(Enum.join(row))
      end)

      IO.puts("")
    end)
  end

  def start_server(:"node1@127.0.0.1") do
    Process.send_after(self(), :tick, @tick_ms)
    IO.inspect("SERVER STARTING")
  end

  def start_server(_), do: nil

  defp handle_responses(responses, state) do
    clients = state.clients

    new_clients =
      responses
      |> Enum.reduce(clients, fn {client, coords}, acc ->
        hit = Battleship.hit(state.pid, coords)
        update_client(acc, client, coords, hit)
      end)

    state
    |> Map.put(:clients, new_clients)
  end

  defp update_client(clients, client, coords, true) do
    old_client = Map.get(clients, client)
    new_hits = [coords | old_client.hits]
    new_client = Map.put(old_client, :hits, new_hits)

    clients
    |> Map.put(client, new_client)
  end

  defp update_client(clients, client, coords, false) do
    old_client = Map.get(clients, client)
    new_misses = [coords | old_client.misses]
    new_client = Map.put(old_client, :misses, new_misses)

    clients
    |> Map.put(client, new_client)
  end

  defp all_hits(clients) do
    clients
    |> Enum.map(fn {_, coords} -> coords.hits end)
    |> List.flatten()
  end

  defp all_misses(clients) do
    clients
    |> Enum.map(fn {_, coords} -> coords.misses end)
    |> List.flatten()
  end

  defp write(position, ship_positions, hits, misses) do
    cond do
      Enum.member?(hits, position) ->
        # (IO.ANSI.red() <> "*") |> IO.write()
        IO.write("💣")

      Enum.member?(misses, position) ->
        # (IO.ANSI.color(10) <> "^") |> IO.write()
        IO.write("❌")

      Enum.member?(ship_positions, position) ->
        IO.write("🚢")

      true ->
        IO.write("🌊")
    end
  end
end
