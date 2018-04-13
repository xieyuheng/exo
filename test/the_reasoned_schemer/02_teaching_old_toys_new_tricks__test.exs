defmodule Ch02 do
  use ExUnit.Case, async: true

  import Exo

  test "simple unification" do
    run 10, x do
      [1, 2, 3] <~> [1, 2, x]
    end
    |> (fn results ->
      assert results === [3]
    end).()
  end

end
