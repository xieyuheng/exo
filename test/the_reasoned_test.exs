defmodule TheReasonedTest do
  use ExUnit.Case, async: true

  import Exo
  import TheReasoned

  def assert_eq(x, y) do
    assert x === y
  end

  describe "(1. Playthings)" do
    test "1:1-55" do
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

      x = false
      run q do
        x <~> q
      end
      |> assert_eq([false])

      run q do
        fresh [x] do
          true <~> x
          true <~> q
        end
      end
      |> assert_eq([true])

      run q do
        fresh [x] do
          x <~> true
          true <~> q
        end
      end
      |> assert_eq([true])

      run q do
        fresh [x] do
          x <~> true
          q <~> true
        end
      end
      |> assert_eq([true])

      run _ do
        succeed()
      end
      |> assert_eq([:_0])

      run r do
        fresh [x, y] do
          [x, y] <~> r
        end
      end
      |> assert_eq([[:_0, :_1]])

      # run r do
      #   fresh [x, y] do
      #     [x, y, x] <~> r
      #   end
      # end
      # |> assert_eq([[:_0, :_1, :_0]])
      # # why [[:_2, :_1, :_2]] ?

      run q do
        false <~> q
        true <~> q
      end
      |> assert_eq([])

      run q do
        false <~> q
        false <~> q
      end
      |> assert_eq([false])

      run r do
        fresh x do
          x <~> r
        end
      end
      |> assert_eq([:_0])

      run q do
        fresh x do
          true <~> x
          x <~> q
        end
      end
      |> assert_eq([true])

      run q do
        fresh x do
          x <~> q
          true <~> x
        end
      end
      |> assert_eq([true])

      run _ do
        oro do
          fail()
          succeed()
        end
      end
      |> assert_eq([:_0])

      run _ do
        oro do
          ando do succeed(); succeed() end
          ando do fail(); fail() end
        end
      end
      |> assert_eq([:_0])

      run x do
        oro do
          ando do :olive <~> x; succeed() end
          ando do :oil <~> x; succeed() end
          ando do fail(); fail() end
        end
      end
      |> assert_eq([:olive, :oil])

      run x do
        oro do
          :olive <~> x
          :oil <~> x
        end
      end
      |> assert_eq([:olive, :oil])

      run x do
        oro do
          ando do :virgin <~> x; fail() end
          ando do :olive <~> x; succeed() end
          ando do succeed(); succeed() end
          ando do :oil <~> x; succeed() end
          ando do fail(); fail() end
        end
      end
      |> assert_eq([:olive, :_0, :oil])

      run 2, x do
        oro do
          ando do :extra <~> x; succeed() end
          ando do :virgin <~> x; fail() end
          ando do :olive <~> x; succeed() end
          ando do :oil <~> x; succeed() end
          ando do fail(); fail() end
        end
      end
      |> assert_eq([:extra, :olive])

      run r do
        fresh [x, y] do
          :split <~> x
          :pea <~> y
          [x, y] <~> r
        end
      end
      |> assert_eq([[:split, :pea]])

      run r do
        fresh [x, y] do
          oro do
            ando do :split <~> x; :pea <~> y end
            ando do :navy <~> x; :bean <~> y end
          end
          [x, y] <~> r
        end
      end
      |> assert_eq([[:split, :pea], [:navy, :bean]])

      run r do
        fresh [x, y] do
          oro do
            ando do :split <~> x; :pea <~> y end
            ando do :navy <~> x; :bean <~> y end
          end
          [x, y, :soup] <~> r
        end
      end
      |> assert_eq([[:split, :pea, :soup], [:navy, :bean, :soup]])
    end

    def teacupo(x) do
      oro do
        :tea <~> x
        :cup <~> x
      end
    end

    test "1:56 teacupo" do
      run x do
        teacupo(x)
      end
      |> assert_eq([:tea, :cup])
    end

    test "1:57 calling teacupo" do
      run r do
        fresh [x, y] do
          oro do
            ando do teacupo(x); true <~> y; succeed() end
            ando do false <~> x; true <~> y; succeed() end
            ando do fail(); fail() end
          end
          [x, y] <~> r
        end
      end
      |> assert_eq([[:tea, true], [:cup, true], [:false, true]])
    end

    test "1:58 by oro" do
      run r do
        fresh [x, y, z] do
          oro do
            ando do y <~> x; fresh [x] do z <~> x end end
            ando do fresh [x] do y <~> x end; z <~> x end
          end
          [y, z] <~> r
        end
      end
      |> assert_eq([[:_0, :_1], [:_0, :_1]])
    end

    test "1:58 by conde" do
      run r do
        fresh [x, y, z] do
          conde do
            [ y <~> x,  fresh [x] do z <~> x end ]
            [ fresh [x] do y <~> x end,  z <~> x ]
          end
          [y, z] <~> r
        end
      end
      |> assert_eq([[:_0, :_1], [:_0, :_1]])
    end

    test "1:59 by conde" do
      run r do
        fresh [x, y, z] do
          conde do
            [ y <~> x,  fresh [x] do z <~> x end ]
            [ fresh [x] do y <~> x end,  z <~> x ]
          end
          x <~> false
          [y, z] <~> r
        end
      end
      |> assert_eq([[false, :_0], [:_0, false]])
    end

    test "1:60" do
      run q do
        with a = true <~> q,
             _b = false <~> q,
          do: a
      end
      |> assert_eq([true])

      run q do
        with _a = true <~> q,
             b = false <~> q,
          do: b
      end
      |> assert_eq([false])
    end

    test "1:61" do
      run q do
        with a = true <~> q,
             _b = (fresh [x] do x <~> q; false <~> x end),
             _c = (conde do [true <~> q]; [false <~> q] end),
          do: a
      end
      |> assert_eq([true])

      run q do
        with _a = true <~> q,
             b = (fresh [x] do x <~> q; false <~> x end),
             _c = (conde do [true <~> q]; [false <~> q] end),
          do: b
      end
      |> assert_eq([false])

      run q do
        with _a = true <~> q,
             _b = (fresh [x] do x <~> q; false <~> x end),
             c = (conde do [true <~> q]; [false <~> q] end),
          do: c
      end
      |> assert_eq([true, false])
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
