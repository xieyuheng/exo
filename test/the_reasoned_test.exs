defmodule TheReasonedTest do
  use ExUnit.Case, async: true

  import Exo
  import TheReasoned

  def assert_eq(x, y) do
    assert x === y
  end

  test "conso" do
    run_all q do
      conso(1, 2, q)
    end
    |> assert_eq([[1 | 2]])
  end

  test "appendo" do
    run_all q do
      appendo([1], [2], q)
    end
    |> assert_eq([[1, 2]])

    run_all q do
      appendo([1], q, [1, 2, 3])
    end
    |> assert_eq([[2, 3]])
  end

end
