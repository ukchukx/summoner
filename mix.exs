defmodule Summoner.MixProject do
  use Mix.Project

  def project do
    [
      app: :summoner,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Summoner.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:httpotion, "~> 3.1.0"}
    ]
  end
end
