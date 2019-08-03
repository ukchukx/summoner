defmodule Summoner do
  @moduledoc """
  Documentation for Summoner.
  """

  require Logger

  @riot_client Summoner.RiotClient

  @doc """
  Retrieve summoner info
  """
  def find_recently_played_with_matches(summoner_name) do
    case @riot_client.get_summoner(summoner_name) do
      {:ok, %{"accountId" => account_id} = summoner} ->
        case @riot_client.get_match_list(account_id) do
          {:ok, %{"matches" => matches}} ->
            player_infos =
              matches
              |> Enum.map(fn %{"gameId" => match_id} -> Task.async(fn -> process_match(match_id) end) end)
              |> Enum.flat_map(&Task.await(&1, 10_000))
              |> Enum.filter(&is_map/1)

            [%{account_id => %{info: summoner_info(summoner), matches: matches}} | player_infos]

          {:error, _} -> "Could not get matches"
        end
      {:error, _} = e ->
        IO.inspect e
        "Could not fetch summoner"
    end
  end

  defp extract_players_from_match(%{"participantIdentities" => identities}) when is_list(identities) do
    identities
    |> Enum.map(&(&1["player"]))
    |> Enum.map(&summoner_info/1)
  end

  defp extract_players_from_match(_), do: []

  defp summoner_info(map) do
    %{
      "accountId" => Map.get(map, "accountId", ""),
      "name" => Map.get(map, "name", Map.get(map, "summonerName", "")),
      "id" => Map.get(map, "id", Map.get(map, "summonerId", ""))
    }
  end

  defp process_match(match_id) when is_integer(match_id) do
    case @riot_client.get_match(match_id) do
      {:ok, match} ->
        match
        # I know it's possible to parallelize these requests, but I don't want to run afoul of Riot
        # rate limit
        |> extract_players_from_match
        |> Enum.map(fn %{"accountId" => account_id} = info ->
          case @riot_client.get_match_list(account_id) do
            {:ok, %{"matches" => matches}} ->
              %{account_id => %{info: summoner_info(info), matches: matches}}
            {:error, _} ->
              %{account_id => %{info: summoner_info(info), matches: []}}
          end
        end)

      {:error, _} = err -> err
    end
  end

  defp process_match(_), do: {:error, :invalid_match_id}
end
