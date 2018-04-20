defmodule TheReasonedTest do
  use ExUnit.Case, async: true

  import Exo
  import TheReasoned

  def assert_eq(x, y) do
    assert x === y
  end

  describe "(1. Playthings)" do
    test "1:10" do
      run _ do
        fail()
      end
      |> assert_eq([])
    end

    test "1:11" do
      run q do
        true <~> q
      end
      |> assert_eq([true])
    end

    test "1:12" do
      run q do
        fail()
        true <~> q
      end
      |> assert_eq([])
    end

    test "1:13" do
      run q do
        succeed()
        true <~> q
      end
      |> assert_eq([true])
    end

    test "1:15" do
      run r do
        succeed()
        :corn <~> r
      end
      |> assert_eq([:corn])
    end

    test "1:17" do
      run r do
        fail()
        :corn <~> r
      end
      |> assert_eq([])
    end

    test "1:18" do
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
    end

    test "1:23" do
      run q do
        fresh [x] do
          true <~> x
          true <~> q
        end
      end
      |> assert_eq([true])
    end

    test "1:26" do
      run q do
        fresh [x] do
          x <~> true
          true <~> q
        end
      end
      |> assert_eq([true])
    end

    test "1:27" do
      run q do
        fresh [x] do
          x <~> true
          q <~> true
        end
      end
      |> assert_eq([true])
    end

    test "1:28" do
      run _ do
        succeed()
      end
      |> assert_eq([:_0])
    end

    test "1:30" do
      run r do
        fresh [x, y] do
          [x, y] <~> r
        end
      end
      |> assert_eq([[:_0, :_1]])
    end

    test "1:32" do
      run r do
        fresh [x, y] do
          [x, y, x] <~> r
        end
      end
      |> assert_eq([[:_0, :_1, :_0]])
    end

    test "1:34" do
      run q do
        false <~> q
        true <~> q
      end
      |> assert_eq([])
    end

    test "1:35" do
      run q do
        false <~> q
        false <~> q
      end
      |> assert_eq([false])
    end

    test "1:37" do
      run r do
        fresh x do
          x <~> r
        end
      end
      |> assert_eq([:_0])
    end

    test "1:38" do
      run q do
        fresh x do
          true <~> x
          x <~> q
        end
      end
      |> assert_eq([true])
    end

    test "1:39" do
      run q do
        fresh x do
          x <~> q
          true <~> x
        end
      end
      |> assert_eq([true])
    end

    test "1:45" do
      run _ do
        conde do
          [fail(), fail()]
          [succeed()]
        end
      end
      |> assert_eq([:_0])
    end

    test "1:46" do
      run _ do
        conde do
          [succeed(), succeed()]
          [fail()]
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
    end

    test "1:47 by oro" do
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
    end

    test "1:47 by conde" do
      run x do
        conde do
          [:olive <~> x, succeed()]
          [:oil <~> x, succeed()]
          [fail(), fail()]
        end
      end
      |> assert_eq([:olive, :oil])

      run x do
        conde do
          [:olive <~> x]
          [:oil <~> x]
        end
      end
      |> assert_eq([:olive, :oil])
    end

    test "1:50 by oro" do
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
    end

    test "1:50 by conde" do
      run x do
        conde do
          [:virgin <~> x, fail()]
          [:olive <~> x, succeed()]
          [succeed(), succeed()]
          [:oil <~> x, succeed()]
          [fail(), fail()]
        end
      end
      |> assert_eq([:olive, :_0, :oil])
    end

    test "1:52 by oro" do
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
    end

    test "1:52 by conde" do
      run 2, x do
        conde do
          [:extra <~> x, succeed()]
          [:virgin <~> x, fail()]
          [:olive <~> x, succeed()]
          [:oil <~> x, succeed()]
          [fail(), fail()]
        end
      end
      |> assert_eq([:extra, :olive])
    end

    test "1:53" do
      run r do
        fresh [x, y] do
          :split <~> x
          :pea <~> y
          [x, y] <~> r
        end
      end
      |> assert_eq([[:split, :pea]])
    end

    test "1:54 by oro" do
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
    end

    test "1:54 by conde" do
      run r do
        fresh [x, y] do
          conde do
            [:split <~> x, :pea <~> y]
            [:navy <~> x, :bean <~> y]
          end
          [x, y] <~> r
        end
      end
      |> assert_eq([[:split, :pea], [:navy, :bean]])
    end

    test "1:55 by oro" do
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

    test "1:55 by conde" do
      run r do
        fresh [x, y] do
          conde do
            [:split <~> x, :pea <~> y]
            [:navy <~> x, :bean <~> y]
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
          conde do
            [teacupo(x), true <~> y, succeed()]
            [false <~> x, true <~> y, succeed()]
            [fail(), fail()]
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
    test "2:1" do
      with x = fn a -> a end,
           y = :c do
        x.(y)
      end
      |> assert_eq(:c)
    end

    test "2:6" do
      run r do
        caro([:a, :c, :o, :r, :n], r)
      end
      |> assert_eq([:a])
    end

    test "2:7" do
      run q do
        caro([:a, :c, :o, :r, :n], :a)
        true <~> q
      end
      |> assert_eq([true])
    end

    test "2:8" do
      run r do
        fresh [x, y] do
          caro([r, y], x)
          :pear <~> x
        end
      end
      |> assert_eq([:pear])
    end

    test "2:10" do
      cons(car([:grape, :raisin, :pear]), car([[:a], [:b], [:c]]))
      |> assert_eq([:grape, :a])
    end

    test "2:11" do
      run r do
        fresh [x, y] do
          caro([:grape, :raisin, :pear], x)
          caro([[:a], [:b], [:c]], y)
          cons(x, y) <~> r
        end
      end
      |> assert_eq([[:grape, :a]])
    end

    test "2:14" do
      car(cdr([:a, :c, :o, :r, :n]))
      |> assert_eq(:c)
    end

    test "2:15 note about the unnesting" do
      run r do
        fresh [v] do
          cdro([:a, :c, :o, :r, :n], v)
          caro(v, r)
        end
      end
      |> assert_eq([:c])
    end

    test "2:17" do
      cons(cdr([:grape, :raisin, :pear]), car([[:a], [:b], [:c]]))
      |> assert_eq([[:raisin, :pear], :a])
    end

    test "2:18" do
      run r do
        fresh [x, y] do
          cdro([:grape, :raisin, :pear], x)
          caro([[:a], [:b], [:c]], y)
          cons(x, y) <~> r
        end
      end
      |> assert_eq([[[:raisin, :pear], :a]])
    end

    test "2:19" do
      run q do
        cdro([:a, :c, :o, :r, :n], [:c, :o, :r, :n])
        true <~> q
      end
      |> assert_eq([true])
    end

    test "2:20" do
      run x do
        cdro([:c, :o, :r, :n], [x, :r, :n])
      end
      |> assert_eq([:o])
    end

    test "2:21" do
      run l do
        fresh [x] do
          cdro(l, [:c, :o, :r, :n])
          caro(l, x)
          :a <~> x
        end
      end
      |> assert_eq([[:a, :c, :o, :r, :n]])
    end

    test "2:22" do
      run l do
        conso([:a, :b, :c], [:d, :e], l)
      end
      |> assert_eq([[[:a, :b, :c], :d, :e]])
    end

    test "2:23" do
      run x do
        conso(x, [:a, :b, :c], [:d, :a, :b, :c])
      end
      |> assert_eq([:d])
    end

    test "2:24" do
      run r do
        fresh [x, y, z] do
          [:e, :a, :d, x] <~> r
          conso(y, [:a, z, :c], r)
        end
      end
      |> assert_eq([[:e, :a, :d, :c]])
    end

    test "2:25" do
      run x do
        conso(x, [:a, x, :c], [:d, :a, x, :c])
      end
      |> assert_eq([:d])
    end

    test "2:26" do
      run l do
        fresh [x] do
          [:d, :a, x, :c] <~> l
          conso(x, [:a, x, :c], l)
        end
      end
      |> assert_eq([[:d, :a, :d, :c]])
    end

    test "2:27" do
      run l do
        fresh [x] do
          conso(x, [:a, x, :c], l)
          [:d, :a, x, :c] <~> l
        end
      end
      |> assert_eq([[:d, :a, :d, :c]])
    end

    test "2:29" do
      run l do
        fresh [d, x, y, w, s] do
          conso(w, [:a, :n, :s], s)
          cdro(l, s)
          caro(l, x)
          :b <~> x
          cdro(l, d)
          caro(d, y)
          :e <~> y
        end
      end
      |> assert_eq([[:b, :e, :a, :n, :s]])
    end

    test "2:32" do
      run q do
        nullo([:grape, :raisin, :pear])
        true <~> q
      end
      |> assert_eq([])
    end

    test "2:33" do
      run q do
        nullo([])
        true <~> q
      end
      |> assert_eq([true])
    end

    test "2:34" do
      run x do
        nullo(x)
      end
      |> assert_eq([[]])
    end

    test "2:38" do
      run q do
        eqo(:pear, :plum)
        true <~> q
      end
      |> assert_eq([])
    end

    test "2:39" do
      run q do
        eqo(:plum, :plum)
        true <~> q
      end
      |> assert_eq([true])
    end

    test "2:52" do
      run r do
        fresh [x, y] do
          [x, y, :salad] <~> r
        end
      end
      |> assert_eq([[:_0, :_1, :salad]])
    end

    test "2:54" do
      run q do
        pairo(cons(q, q))
        true <~> q
      end
      |> assert_eq([true])
    end

    test "2:55" do
      run q do
        pairo([])
        true <~> q
      end
      |> assert_eq([])
    end

    test "2:56" do
      run q do
        pairo(:pair)
        true <~> q
      end
      |> assert_eq([])
    end

    test "2:57" do
      run x do
        pairo(x)
      end
      |> assert_eq([[:_0 | :_1]])
    end

    test "2:58" do
      run r do
        pairo([r, :pair])
      end
      |> assert_eq([:_0])
    end
  end

  describe "(3. Seeing Old Friends in New Ways)" do
    test "3:1" do
      list?([[:a], [:a, :b], :c])
      |> assert_eq(true)
    end

    test "3:2" do
      list?([])
      |> assert_eq(true)
    end

    test "3:3" do
      list?(:s)
      |> assert_eq(false)
    end

    test "3:4" do
      list?([:d, :a, :t, :e | :s])
      |> assert_eq(false)
    end

    test "3:7" do
      run x do
        listo([:a, :b, x, :d])
      end
      |> assert_eq([:_0])
    end

    test "3:10" do
      run 1, x do
        listo([:a, :b, :c | x])
      end
      |> assert_eq([[]])
    end

    test "3:14" do
      run 5, x do
        listo([:a, :b, :c | x])
      end
      |> assert_eq(
        [
          [],
          [:_0],
          [:_0, :_1],
          [:_0, :_1, :_2],
          [:_0, :_1, :_2, :_3],
        ])
    end

    test "3:20" do
      run 1, l do
        lolo(l)
      end
      |> assert_eq([[]])
    end

    test "3:21" do
      run q do
        fresh [x, y] do
          lolo([[:a, :b], [x, :c], [:d, y]])
          true <~> q
        end
      end
      |> assert_eq([true])
    end

    test "3:22" do
      run 1, q do
        fresh [x] do
          lolo([[:a, :b] | x])
          true <~> q
        end
      end
      |> assert_eq([true])
    end

    test "3:32" do
      run q do
        twinso([:tofu, :tofu])
        true <~> q
      end
      |> assert_eq([true])
    end

    test "3:33" do
      run z do
        twinso([z, :tofu])
      end
      |> assert_eq([:tofu])
    end

    test "3:38" do
      run 1, z do
        loto([[:g, :g] | z])
      end
      |> assert_eq([[]])
    end

    test "3:42" do
      run 5, z do
        loto([[:g, :g] | z])
      end
      |> assert_eq([
        [],
        [[:_0, :_0]],
        [[:_0, :_0], [:_1, :_1]],
        [[:_0, :_0], [:_1, :_1], [:_2, :_2]],
        [[:_0, :_0], [:_1, :_1], [:_2, :_2], [:_3, :_3]],
      ])
    end

    test "3:45" do
      run 5, r do
        fresh [w, x, y, z] do
          loto([[:g, :g], [:e, w], [x, y] | z])
          [w, [x, y], z] <~> r
        end
      end
      |> assert_eq([
        [:e, [:_0, :_0], []],
        [:e, [:_0, :_0], [[:_1, :_1]]],
        [:e, [:_0, :_0], [[:_1, :_1], [:_2, :_2]]],
        [:e, [:_0, :_0], [[:_1, :_1], [:_2, :_2], [:_3, :_3]]],
        [:e, [:_0, :_0], [[:_1, :_1], [:_2, :_2], [:_3, :_3], [:_4, :_4]]]
      ])
    end

    test "3:49" do
      run 3, out do
        fresh [w, x, y, z] do
          [[:g, :g], [:e, w], [x, y] | z] <~> out
          listofo(&twinso/1, out)
        end
      end
      |> assert_eq([
        [[:g, :g], [:e, :e], [:_0, :_0]],
        [[:g, :g], [:e, :e], [:_0, :_0], [:_1, :_1]],
        [[:g, :g], [:e, :e], [:_0, :_0], [:_1, :_1], [:_2, :_2]]
      ])
    end

    test "3:53" do
      member?(:olive, [:virgin, :olive, :oil])
      |> assert_eq(true)
    end

    test "3:57" do
      run q do
        membero(:olive, [:virgin, :olive, :oil])
        true <~> q
      end
      |> assert_eq([true])
    end

    test "3:58" do
      run y do
        membero(y, [:hummus, :with, :pita])
      end
      |> assert_eq([:hummus, :with, :pita])
    end

    test "3:66" do
      run x do
        membero(:e, [:pasta, x, :fagioli])
      end
      |> assert_eq([:e])
    end

    test "3:71" do
      run r do
        fresh [x, y] do
          membero(:e, [:pasta, x, :fagioli, y])
          [x, y] <~> r
        end
      end
      |> assert_eq([[:e, :_0], [:_0, :e]])
    end

    test "3:73" do
      run 1, l do
        membero(:tofu, l)
      end
      |> assert_eq([[:tofu | :_0]])
    end

    test "3:76" do
      run 5, l do
        membero(:tofu, l)
      end
      |> assert_eq([
        [:tofu | :_0],
        [:_0, :tofu | :_1],
        [:_0, :_1, :tofu | :_2],
        [:_0, :_1, :_2, :tofu | :_3],
        [:_0, :_1, :_2, :_3, :tofu | :_4],
      ])
    end

    test "3:80" do
      run 5, l do
        pmembero(:tofu, l)
      end
      |> assert_eq([
        [:tofu],
        [:_0, :tofu],
        [:_0, :_1, :tofu],
        [:_0, :_1, :_2, :tofu],
        [:_0, :_1, :_2, :_3, :tofu],
      ])
    end

    test "3:81" do
      run q do
        pmembero(:tofu, [:a, :b, :tofu, :d, :tofu])
        true <~> q
      end
      |> assert_eq([true])

      run q do
        membero(:tofu, [:a, :b, :tofu, :d, :tofu])
        true <~> q
      end
      |> assert_eq([true, true])
    end

    test "3:96" do
      first_value([:pasta, :e, :fagioli])
      |> assert_eq([:pasta])

      first_value([])
      |> assert_eq([])
    end

    test "3:100" do
      run x do
        memberrevo(x, [:pasta, :e, :fagioli])
      end
      |> assert_eq([:fagioli, :e, :pasta])
    end
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
end
