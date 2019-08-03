defmodule Summoner.RiotClient do
  @api_host Application.get_env(:summoner, :riot_api_host)
  @timeout 10_000

  require Logger

  def get_summoner(name) do
    url =
      @api_host
      |> Kernel.<>("summoner/v4/summoners/by-name/#{name}")
      |> append_api_key

    Logger.debug("Get summoner #{name}")

    try do
      url
      |> HTTPotion.get([
        headers: headers(),
        timeout: @timeout
      ])
      |> process_response
    rescue
      _ -> {:error, :something_bad_happened}
    end
  end

  def get_match_list(account_id) do
    url =
      @api_host
      |> Kernel.<>("match/v4/matchlists/by-account/#{account_id}")
      |> append_api_key
      |> Kernel.<>("&beginIndex=0&endIndex=5")

    Logger.debug("Get match list for account with id: " <> account_id)

    try do
      url
      |> HTTPotion.get([
        headers: headers(),
        timeout: @timeout
      ])
      |> process_response
    rescue
      _ -> {:error, :something_bad_happened}
    end
  end

  def get_match(match_id) do
    url =
      @api_host
      |> Kernel.<>("match/v4/matches/#{match_id}")
      |> append_api_key

    Logger.debug("Get match with id: #{match_id}")

    try do
      url
      |> HTTPotion.get([
        headers: headers(),
        timeout: @timeout
      ])
      |> process_response
    rescue
      _ -> {:error, :something_bad_happened}
    end
  end

  defp process_response(response) do
    case response do
      %HTTPotion.Response{body: body, status_code: status_code} ->
        case HTTPotion.Response.success?(response) do
          true ->
            {:ok, Jason.decode!(body)}
          false ->
            case status_code == 404 do
              true -> {:error, :not_found}
              false -> {:error, :request_failed}
            end
        end

      _ -> {:error, :could_not_fetch}
    end
  end

  defp append_api_key(url), do: url <> "?api_key=" <> Application.get_env(:summoner, :riot_api_key)

  defp headers do
    [
      "Content-Type": "application/json",
      "Accepts": "application/json",
    ]
  end
end
