defmodule SummonerTest do
  use ExUnit.Case
  doctest Summoner

  test "greets the world" do
    assert Summoner.hello() == :world
  end
end
