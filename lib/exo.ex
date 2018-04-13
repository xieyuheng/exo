defmodule Exo do

  ### microkanren

  defmodule Var do
    defstruct [
      id: 0
    ]
  end

  def var_c(id) do
    # -> Nat -- Var
    %Var{id: id}
  end

  def var?(x) do
    # -> Any -- Bool
    case x do
      %Var{} -> true
      _ -> false
    end
  end

  # Substitution = Var Term Map

  def walk(u, s) do
    # walk until the term is not Var
    #   does not care about other Vars in the result term
    # -> Term, Substitution -- Term
    case u do
      %Var{} ->
        found = Map.get(s, u)
        if found do
          walk(found, s)
        else
          u
        end

      _ -> u
    end
  end

  def unify(s, u, v) do
    # -> Term, Term, Substitution
    # -- | Substitution
    #      False
    u = walk(u, s)
    v = walk(v, s)
    case {u, v} do
      {%Var{id: id}, %Var{id: id}} -> s

      {%Var{}, _} -> Map.put(s, u, v)

      {_, %Var{}} -> Map.put(s, v, u)

      {[u_head | u_tail], [v_head | v_tail]} ->
        s = unify(s, u_head, v_head)
        s && unify(s, u_tail, v_tail)

      _ -> u === v && s
    end
  end

  defmodule State do
    defstruct [
      id_counter: 0,
      substitution: %{}
    ]
  end

  def state_c(c, s) do
    # -> Nat, Substitution -- State
    %State{id_counter: c, substitution: s}
  end

  def empty_state do
    # -> -- State
    %State{id_counter: 0, substitution: %{}}
  end

  # Goal = (-> State -- StateStream)

  def eqo(u, v) do
    # -> Trem, Trem -- Goal
    fn state ->
      s = unify(Map.get(state, :substitution), u, v)
      if s do
        [%State{state | substitution: s}]
      else
        []
      end
    end
  end

  def x <~> y do
    eqo(x, y)
  end

  def call_with_fresh(fun) do
    # -> (-> Var -- Goal) -- Goal
    fn state ->
      id = Map.get(state, :id_counter)
      goal = fun.(var_c(id))
      goal.(%State{state | id_counter: id+1})
    end
  end

  def disj(g1, g2) do
    # -> Goal, Goal -- Goal
    fn state ->
      s1 = g1.(state)
      s2 = g2.(state)
      mplus(s1, s2)
    end
  end

  def conj(g1, g2) do
    # -> Goal, Goal -- Goal
    fn state ->
      s1 = g1.(state)
      bind(s1, g2)
    end
  end

  def mplus(s1, s2) do
    # -> StateStream, StateStream -- StateStream
    case s1 do
      [] -> s2

      trunk when is_function(trunk) ->
        # use interleaving
        #   to implement a complete search strategy
        # ><><><
        #   maybe we can use actor model to parallelize this
        fn -> mplus(s2, trunk.()) end

      [head | tail] -> [head | mplus(tail, s2)]
    end
  end

  def bind(s, g) do
    # -> StateStream, Goal -- StateStream
    case s do
      [] -> []

      trunk when is_function(trunk) ->
        fn -> bind(trunk.(), g) end

      [head | tail] -> mplus(g.(head), bind(tail, g))
    end
  end

  ### some macros

  defmacro zzz(g) do
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

  defmacro ando(exp) do
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

  defmacro oro(exp) do
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

  defmacro fresh(var_list, exp) do
    case var_list do
      {_, _, atom} when is_atom(atom) ->
        var_list = [var_list]
        quote do
          fresh(unquote(var_list), unquote(exp))
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

  ### state_stream to state_list

  def pull(state_stream) do
    if is_function(state_stream) do
      pull(state_stream.())
    else
      state_stream
    end
  end

  def take_all(state_stream) do
    state_stream = pull(state_stream)
    case state_stream do
      [] -> []
      [head | tail] -> [head | take_all(tail)]
    end
  end

  def take(state_stream, n) do
    if n === 0 do
      []
    else
      state_stream = pull(state_stream)
      case state_stream do
        [] -> []
        [head | tail] -> [head | take(tail, n-1)]
      end
    end
  end

  ### reification

  def mk_reify(state_list) do
    # -> State List -- Reification List
    Enum.map(state_list, &reify_state_with_1st_var/1)
  end

  def reify_state_with_1st_var(state) do
    # -> State -- Reification
    substitution = Map.get(state, :substitution)
    v = deep_walk(var_c(0), substitution)
    deep_walk(v, reify_s(v, []))
  end

  def deep_walk(v, s) do
    # -> Term, Substitution -- Term
    v = walk(v, s)
    case v do
      %Var{} -> v
      [head | tail] -> [deep_walk(head, s) | deep_walk(tail, s)]
      _ -> v
    end
  end

  def reify_s(v, s) do
    # -> Term, Substitution -- Substitution
    case v do
      %Var{} ->
        n = reify_name(length(s))
        [[v | n] | s]

      [head | tail] -> reify_s(tail, reify_s(head, s))

      _ -> s
    end
  end

  def reify_name(n) do
    # -> Nat -- Atom
    n
    |> Integer.to_string()
    |> (fn s -> "_" <> s end).()
    |> String.to_atom()
  end

  ### user interface

  def call_with_empty_state(goal) do
    # -> Goal -- StateStream
    empty_state() |> goal.()
  end

  defmacro run(n, var, exp) do
    quote do
      fresh(unquote(var), unquote(exp))
      |> call_with_empty_state()
      |> take(unquote(n))
      |> mk_reify()
    end
  end

  defmacro run_all(var, exp) do
    quote do
      fresh(unquote(var), unquote(exp))
      |> call_with_empty_state()
      |> take_all()
      |> mk_reify()
    end
  end

end
