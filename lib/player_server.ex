defmodule Summoner.PlayerServer do
  use GenServer

  require Logger

  @check_interval 60_000 # 1 minute in milliseconds
  @stop_interval 18_000 # 5 hours in seconds

  def start_link(_args \\ nil) do
    Logger.debug("Starting #{__MODULE__}")

    GenServer.start_link(__MODULE__, %{table: :players}, name: __MODULE__)
  end

  def init(state) do
    Logger.debug("Initializing #{__MODULE__}.")

    send(self(), :init)

    {:ok, state}
  end

  def handle_cast({:load, players}, %{table: table} = state) do
    for player <- players do
      id = player |> Map.keys |> List.first
      %{info: %{"name" => name}, matches: new_matches} = Map.get(player, id)
      match_ids = Enum.map(new_matches, &(&1["gameId"]))
      now = current_time()

      case :ets.lookup(table, name) do
        [] ->
          :ets.insert(table, {name, match_ids, now})

        [{_, old_match_ids, _}] ->
          match_ids
          |> Enum.filter(fn id -> Enum.all?(old_match_ids, &(&1 != id)) end)
          |> case do
            [] -> :ok # No new matches

            new_match_ids -> :ets.insert(table, {id, new_match_ids, now})
          end
      end
    end

    set_timer()

    {:noreply, Map.put(state, :start_time, DateTime.utc_now())}
  end


  def handle_info(:init, %{table: table} = state) do
    :ets.new(table, [:named_table, :set, :public])
    {:noreply, state}
  end

  def handle_info(:check_new, %{table: table, start_time: start_time} = state) do
    Task.start(fn -> print_new_matches(table) end)

    # Set a timer for next minute if we've not passed @stop_interval
    DateTime.utc_now()
    |> DateTime.diff(start_time)
    |> Kernel.>=(@stop_interval)
    |> case do
      true -> :ok
      false -> set_timer()
    end

    {:noreply, state}
  end

  defp print_new_matches(table) do
    table
    |> :ets.tab2list
    |> case do
      [] -> []
      records ->
        IO.puts("\n\n***** #{current_time()} *****\n\n")

        records
    end
    |> Enum.filter(fn {_, new_matches, _} -> length(new_matches) != 0 end)
    |> Enum.each(fn {summoner, new_matches, last_updated} ->
      console_str = """
      -----------------------------------------
      Summoner: #{summoner}
      New matches (updated at #{last_updated}): #{Enum.join(new_matches, ", ")}
      """

      IO.puts(console_str)
    end)
  end

  defp set_timer, do: Process.send_after(self(), :check_new, @check_interval)

  defp current_time, do: DateTime.utc_now |> DateTime.to_string
end
