defmodule ExoTest do
  use ExUnit.Case, async: true

  import Exo
  alias Exo.Var
  alias Exo.State

  test "var" do
    assert Var.p(Var.c(0))
    assert Var.p(Var.c(1))
    assert Var.p(Var.c(2))
    assert Var.c(0) === Var.c(0)
  end

  test "unify" do
    s = unify(%{},
      [:a, :b, :c],
      [:a, :b, :c])
    assert s === %{}

    s = unify(%{},
      [[:a, :b, :c],
       [:a, :b, :c],
       [:a, :b, :c]],
      [[:a, :b, :c],
       [:a, :b, :c],
       [:a, :b, :c]])
    assert s === %{}

    s = unify(%{},
      [Var.c(0), :b, :c],
      [:a, :b, :c])
    assert s === %{Var.c(0) => :a}

    s = unify(%{},
      [[Var.c(0), :b, :c],
       [:a, Var.c(1), :c],
       [:a, :b, Var.c(2)]],
      [[:a, :b, :c],
       [:a, :b, :c],
       [:a, :b, :c]])
    assert s === %{Var.c(0) => :a,
                   Var.c(1) => :b,
                   Var.c(2) => :c}
  end

  test "goal" do
    goal = call_with_fresh fn a -> eqo(a, 5) end
    state_stream = empty_state() |> goal.()
    assert state_stream === [State.c(1, %{Var.c(0) => 5})]

    goal = eqo([1, 2, 3], [1, 2, 3])
    state_stream = empty_state() |> goal.()
    assert state_stream === [State.c(0, %{})]

    goal = eqo([1, 2, 3], [3, 2, 1])
    state_stream = empty_state() |> goal.()
    assert state_stream === []
  end

  def a_and_b do
    g1 = call_with_fresh fn a -> eqo(a, 7) end
    g2 = call_with_fresh fn b ->
      disj(eqo(b, 5), eqo(b, 6))
    end
    conj(g1, g2)
  end

  test "a and b" do
    goal = a_and_b()
    state_stream = empty_state() |> goal.()
    assert state_stream === [
      State.c(2, %{Var.c(0) => 7, Var.c(1) => 5}),
      State.c(2, %{Var.c(0) => 7, Var.c(1) => 6}),
    ]
  end

  # The following query will fail to terminate,
  #   as the call to disj will invoke mplus
  #   to collect all results and returns them as a list.
  # For an infinite relation, such as fives above,
  #   collecting all the results before returning any of them
  #   ensures no results are returned.

  # def fives x do
  #   disj(eqo(x, 5), fives(x))
  # end

  def fives x do
    # disj(eqo(x, 5), zzz(fives(x)))
    # disj(eqo(x, 5), ando([fives(x)]))
    disj(eqo(x, 5), ando do fives(x) end)
  end

  test "fives" do
    goal = call_with_fresh(&fives/1)
    state_stream = empty_state() |> goal.()
    assert hd(state_stream) === State.c(1, %{Var.c(0) => 5})
    assert is_function tl(state_stream)
  end

  # with macros

  test "a and b in macros" do
    goal = fresh [a, b] do
      eqo a, 7
      oro do
        eqo b, 5
        eqo b, 6
      end
    end
    state_stream = empty_state() |> goal.()
    assert take_all(state_stream) === [
      State.c(2, %{Var.c(0) => 7, Var.c(1) => 5}),
      State.c(2, %{Var.c(0) => 7, Var.c(1) => 6}),
    ]
  end

  test "run ten fives" do
    run 10, x do
      fives(x)
    end
    |> (fn results ->
      assert results === [5, 5, 5, 5, 5, 5, 5, 5, 5, 5]
    end).()
  end

  test "simple unification" do
    run 10, x do
      [1, 2, 3] <~> [1, 2, x]
    end
    |> (fn results ->
      assert results === [3]
    end).()
  end

end