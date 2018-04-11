defmodule Exo do
  defmodule Var do
    defstruct id: 0
  end

  def var_c id do
    # -> Nat -- Var
    %Var{id: id}
  end

  def var? x do
    # -> Any -- Bool
    case x do
      %Var{} -> true
      _ -> false
    end
  end

  # Substitution = Var Term Map

  def walk u, s do
    # -> Term, Substitution -- Term
    case u do
      %Var{} ->
        found = Map.get s, u
        if found do
          walk found, s
        else
          u
        end
      _ -> u
    end
  end

  def unify u, v, s do
    # -> Term, Term, Substitution
    # -- | Substitution
    #      False
    u = walk u, s
    v = walk v, s
    case {u, v} do
      {%Var{id: id}, %Var{id: id}} -> s
      {%Var{}, _} -> Map.put s, u, v
      {_, %Var{}} -> Map.put s, v, u
      {[u_car|u_cdr], [v_car|v_cdr]} ->
        s = unify u_car, v_car, s
        s && unify u_cdr, v_cdr, s
      _ -> u === v && s
    end
  end

  defmodule State do
    defstruct id_counter: 0, substitution: %{}
  end

  def state_c c, s do
    # -> Nat, Substitution -- State
    %State{id_counter: c, substitution: s}
  end

  def empty_state do
    # -> -- State
    %State{}
  end

  # Goal = (-> State -- State Stream)

  def eqo u, v do
    # -> Trem, Trem -- Goal
    fn state ->
      s = unify u, v, Map.get(state, :substitution)
      if s do
        [%State{state | substitution: s}]
      else
        []
      end
    end
  end

  def call_with_fresh fun do
    # -> (-> Var -- Goal) -- Goal
    fn state ->
      id = Map.get(state, :id_counter)
      goal = fun.(var_c(id))
      goal.(%State{state | id_counter: id+1})
    end
  end

  def disj g1, g2 do
    # -> Goal, Goal -- Goal
    fn state ->
      s1 = g1.(state)
      s2 = g2.(state)
      mplus s1, s2
    end
  end

  def conj g1, g2 do
    # -> Goal, Goal -- Goal
    fn state ->
      s1 = g1.(state)
      bind s1, g2
    end
  end

  def mplus s1, s2 do
    # -> State Stream, State Stream -- State Stream
    Stream.concat s1, s2
  end

  def bind s, g do
    # -> State Stream, Goal -- State Stream
    s |> Stream.map(g) |> Stream.concat
  end
end

ExUnit.start

defmodule Exo.Text do
  use ExUnit.Case, async: true

  import Exo

  test "var" do
    assert var_c(0) |> var?
    assert var_c(1) |> var?
    assert var_c(2) |> var?
    assert var_c(0) === var_c(0)
  end

  test "unify" do
    s = unify [:a, :b, :c], [:a, :b, :c], %{}
    assert s === %{}

    s = unify [[:a, :b, :c],
               [:a, :b, :c],
               [:a, :b, :c]],
      [[:a, :b, :c],
       [:a, :b, :c],
       [:a, :b, :c]], %{}
    assert s === %{}

    s = unify [var_c(0), :b, :c], [:a, :b, :c], %{}
    assert s === %{var_c(0) => :a}

    s = unify [[var_c(0), :b, :c],
               [:a, var_c(1), :c],
               [:a, :b, var_c(2)]],
      [[:a, :b, :c],
       [:a, :b, :c],
       [:a, :b, :c]], %{}
    assert s === %{var_c(0) => :a,
                   var_c(1) => :b,
                   var_c(2) => :c}
  end

  test "goal" do
    goal = call_with_fresh fn a -> eqo a, 5 end
    stream = empty_state() |> goal.()
    assert stream === [state_c(1, %{var_c(0) => 5})]

    goal = eqo [1, 2, 3], [1, 2, 3]
    stream = empty_state() |> goal.()
    assert stream === [state_c(0, %{})]

    goal = eqo [1, 2, 3], [3, 2, 1]
    stream = empty_state() |> goal.()
    assert stream === []
  end

  def a_and_b do
    g1 = call_with_fresh fn a -> eqo a, 7 end
    g2 = call_with_fresh fn b ->
      disj(eqo(b, 5), eqo(b, 6))
    end
    conj g1, g2
  end

  test "a and b" do
    goal = a_and_b()
    stream = empty_state() |> goal.()
    list = Enum.take stream, 100
    assert length(list) === 2
    assert list === [
      state_c(2, %{var_c(0) => 7, var_c(1) => 5}),
      state_c(2, %{var_c(0) => 7, var_c(1) => 6}),
    ]
  end
end
