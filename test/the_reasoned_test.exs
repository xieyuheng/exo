defmodule TheReasonedTest do
  use ExUnit.Case, async: true

  import Exo
  import TheReasoned

  def assert_eq(x, y) do
    assert x === y
  end

  describe "(1. Playthings)" do
    test "intro" do
      run _ do
        fail()
      end
      |> assert_eq([])

      run q do
        true <~> q
      end
      |> assert_eq([true])

      run q do
        fail()
        true <~> q
      end
      |> assert_eq([])

      run q do
        succeed()
        true <~> q
      end
      |> assert_eq([true])

      run r do
        succeed()
        :corn <~> r
      end
      |> assert_eq([:corn])

      run r do
        fail()
        :corn <~> r
      end
      |> assert_eq([])

      run q do
        false <~> q
      end
      |> assert_eq([false])

      run q do
        nil <~> q
      end
      |> assert_eq([nil])

      run q do
        [] <~> q
      end
      |> assert_eq([[]])

      run q do
        "" <~> q
      end
      |> assert_eq([""])

      run q do
        '' <~> q
      end
      |> assert_eq([''])
    end
  end

  describe "(2. Teaching Old Toys New Tricks)" do

  end

  describe "(3. Seeing Old Friends in New Ways)" do

  end

  describe "(4. Members Only)" do

  end

  describe "(5. Double Your Fun)" do

  end

  describe "(6. The Fun Never Ends ...)" do

  end

  describe "(7. A Bit Too Much)" do

  end

  describe "(8. Just a Bit More)" do

  end

  describe "(9. Under the Hood)" do

  end

  describe "(10. Thin Ice)" do

  end

  test "conso" do
    run q do
      conso(1, 2, q)
    end
    |> assert_eq([[1 | 2]])
  end

  test "appendo" do
    run q do
      appendo([1], [2], q)
    end
    |> assert_eq([[1, 2]])

    run q do
      appendo([1], q, [1, 2, 3])
    end
    |> assert_eq([[2, 3]])
  end
end
