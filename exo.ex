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
      {[u_head | u_tail], [v_head | v_tail]} ->
        s = unify u_head, v_head, s
        s && unify u_tail, v_tail, s
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

  # Goal = (-> State -- StateStream)

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
    # -> StateStream, StateStream -- StateStream
    case s1 do
      [] -> s2
      trunk when trunk |> is_function ->
        # use interleaving
        #   to implement a complete search strategy
        # ><><><
        #   maybe we can use actor model to parallelize this
        fn -> mplus s2, trunk.() end
      [head | tail] -> [head | mplus(tail, s2)]
    end
  end

  def bind s, g do
    # -> StateStream, Goal -- StateStream
    case s do
      [] -> []
      trunk when trunk |> is_function ->
        fn -> bind trunk.(), g end
      [head | tail] -> mplus g.(head), bind(tail, g)
    end
  end

  defmacro zzz g do
    quote do
      fn state ->
        fn ->
          unquote(g).(state)
        end
      end
    end
  end

  # ando do
  #   g1
  #   g2
  #   g3
  # end

  # ==>

  # ando([g1, g2, g3])

  # ==>

  # conj(zzz(g1),
  #   conj(zzz(g2),
  #     zzz(g3)))

  defmacro ando exp do
    case exp do
      [do: {:__block__, _, list}] ->
        quote do
          ando(unquote(list))
        end
      [do: single] ->
        quote do
          ando(unquote([single]))
        end
      [head | []] ->
        quote do
          zzz(unquote(head))
        end
      [head | tail] ->
        quote do
          conj(zzz(unquote(head)), ando(unquote(tail)))
        end
    end
  end

  defmacro oro exp do
    case exp do
      [do: {:__block__, _, list}] ->
        quote do
          oro(unquote(list))
        end
      [do: single] ->
        quote do
          oro(unquote([single]))
        end
      [head | []] ->
        quote do
          zzz(unquote(head))
        end
      [head | tail] ->
        quote do
          disj(zzz(unquote(head)), oro(unquote(tail)))
        end
    end
  end

  # no conde
  #   we use oro instead of conde for now

  # fresh [a, b, c] do
  #   g1
  #   g2
  #   g3
  # end

  # ==>

  # call_with_fresh fn a ->
  #   call_with_fresh fn b ->
  #     call_with_fresh fn c ->
  #       ando do
  #         g1
  #         g2
  #         g3
  #       end
  #     end
  #   end
  # end

  defmacro fresh vars, exp do
    case vars do
      {_, _, atom} when is_atom(atom) ->
        quote do
          fresh([unquote(vars)], unquote(exp))
        end
      [var | []] ->
        quote do
          call_with_fresh fn unquote(var) ->
            ando(unquote(exp))
          end
        end
      [var | tail] ->
        quote do
          call_with_fresh fn unquote(var) ->
            fresh(unquote(tail), unquote(exp))
          end
        end
    end
  end

  def pull stream do
    if is_function(stream) do
      pull(stream.())
    else
      stream
    end
  end

  def take_all stream do
    stream = pull(stream)
    case stream do
      [] -> []
      [head | tail] -> [head | take_all(tail)]
    end
  end

  def take n, stream do
    if n === 0 do
      []
    else
      stream = pull(stream)
      case stream do
        [] -> []
        [head | tail] -> [head | take(n-1, tail)]
      end
    end
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
    assert stream === [
      state_c(2, %{var_c(0) => 7, var_c(1) => 5}),
      state_c(2, %{var_c(0) => 7, var_c(1) => 6}),
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
    goal = call_with_fresh &fives/1
    stream = empty_state() |> goal.()
    assert hd(stream) === state_c(1, %{var_c(0) => 5})
    assert is_function tl(stream)
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
    stream = empty_state() |> goal.()
    assert take_all(stream) === [
      state_c(2, %{var_c(0) => 7, var_c(1) => 5}),
      state_c(2, %{var_c(0) => 7, var_c(1) => 6}),
    ]
  end

end
