defmodule ExoTest do
  use ExUnit.Case
  doctest Exo

  test "greets the world" do
    assert Exo.hello() == :world
  end
end
