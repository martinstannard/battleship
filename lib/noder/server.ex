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
    # new_state =
    #   state
    #   |> IO.inspect()
    #   |> update_client_list
    #   |> call_clients
    #   |> handle_responses(state)
    #   |> dump

    state = update_client_list(state)

    responses = call_clients(state)

    state = handle_responses(responses, state)

    dump(state)

    Process.send_after(self(), :tick, @tick_ms)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp call_clients(state) do
    clients = Node.list()

    clients
    |> Enum.map(fn client ->
      coords = GenServer.call({:client, client}, :tick)
      hit = Battleship.hit(state.pid, coords)
      GenServer.call({:client, client}, {:update, {coords, hit}})
      {client, coords, hit}
    end)
  end

  defp update_client_list(state) do
    state
    |> Map.put(:clients, new_clients(state.clients))
  end

  defp new_clients(clients) do
    Node.list()
    |> Enum.reduce(clients, fn node, acc ->
      Map.put_new(acc, node, %{hits: [], misses: [], score: 0})
    end)
  end

  defp dump(state) do
    bs = Battleship.state(state.pid)
    ship_positions = List.flatten(bs.ships)
    all_hits = all_hits(state.clients)
    all_misses = all_misses(state.clients)

    IO.write([IO.ANSI.home(), IO.ANSI.clear()])

    %{rows: rows, columns: columns} = Battleship.size()

    0..rows
    |> Enum.each(fn col ->
      0..columns
      |> Enum.each(fn row ->
        write({col, row}, ship_positions, all_hits, all_misses)
      end)

      IO.puts("")
    end)

    IO.puts("")

    state.clients
    |> Enum.each(fn {client, %{score: score}} ->
      IO.puts("#{client} : #{score}")
    end)

    IO.puts("Ships: #{length(bs.ships)}")
    # IO.inspect(bs.ships)

    state
  end

  def start_server(:"node1@10.0.1.10") do
    Process.send_after(self(), :tick, @tick_ms)
    IO.inspect("SERVER STARTING")
  end

  def start_server(_), do: nil

  defp handle_responses(responses, state) do
    clients = state.clients

    new_clients =
      responses
      |> Enum.reduce(clients, fn {client, coords, hit}, acc ->
        update_client(acc, client, coords, hit)
      end)

    state
    |> Map.put(:clients, new_clients)
  end

  defp update_client(clients, client, coords, {true, last}) do
    old_client = Map.get(clients, client)
    new_hits = [coords | old_client.hits]

    new_client =
      old_client
      |> Map.put(:hits, new_hits)
      |> Map.put(:score, old_client.score + score(true, last))

    clients
    |> Map.put(client, new_client)
  end

  defp update_client(clients, client, coords, {false, _}) do
    old_client = Map.get(clients, client)
    new_misses = [coords | old_client.misses]
    new_client = Map.put(old_client, :misses, new_misses)

    clients
    |> Map.put(client, new_client)
  end

  defp score(true, true), do: 5000
  defp score(true, _), do: 5

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
