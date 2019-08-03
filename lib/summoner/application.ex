defmodule Summoner.Application do
  use Application

  require Logger

  def start(_type, _args) do
    Logger.debug("Starting #{__MODULE__}")

    Supervisor.start_link([Summoner.PlayerServer], [strategy: :one_for_one, name: Summoner.Supervisor])
  end
end
