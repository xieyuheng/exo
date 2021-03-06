defmodule Exo do

@moduledoc """
Logic programming in elixir.
"""

defmodule Var do
  defstruct [
    id: 0
  ]

  @type t :: %Var{id: integer}

  @spec c(integer) :: Var.t
  def c(id) do
    %Var{id: id}
  end

  @spec p(any) :: boolean
  def p(x) do
    case x do
      %Var{} -> true
      _ -> false
    end
  end
end

@typedoc"""
We tried to support all unifiable datatype of elixir.
"""
@type value_t ::
        atom
      | integer
      | float
      | boolean
      | String.t
      | Var.t
      | [value_t]
      | tuple
      | map

@type substitution_t :: %{required(Var.t) => value_t}

@doc"""
One-step walking

Walking until the value is not Var.t,
which does not care about other vars in the result value.
"""
@spec walk(value_t, substitution_t) :: value_t
def walk(u, s) do
  case u do
    %Var{} ->
      case Map.fetch(s, u) do
        {:ok, v} -> walk(v, s)
        :error -> u
      end

    _ -> u
  end
end

@spec unify(substitution_t, value_t, value_t) ::
        substitution_t
      | false
def unify(s, u, v) do
  u = walk(u, s)
  v = walk(v, s)
  nu = normalize_value(u)
  nv = normalize_value(v)
  case {nu, nv} do
    {%Var{id: id}, %Var{id: id}} -> s

    {%Var{}, _} -> Map.put(s, u, v)

    {_, %Var{}} -> Map.put(s, v, u)

    {[u_head | u_tail], [v_head | v_tail]} ->
      s = unify(s, u_head, v_head)
      s && unify(s, u_tail, v_tail)

    _ -> (u === v) && s
  end
end

def normalize_value(v) do
  cond do
    is_tuple(v) -> Tuple.to_list(v)

    is_map(v) && not Var.p(v) -> Map.to_list(v)

    true -> v
  end
end

defmodule State do
  defstruct [
    id_counter: 0,
    substitution: Map.new(),
  ]

  @type t :: %State{
    id_counter: integer,
    substitution: Exo.substitution
  }

  @spec c(integer, Exo.substitution) :: State.t
  def c(c, s) do
    %State{id_counter: c, substitution: s}
  end
end

@spec empty_state() :: State.t
def empty_state do
  State.c(0, Map.new())
end

@type state_stream_t ::
        maybe_improper_list(State.t, state_stream_t)
      | (-> state_stream_t)

@type goal_t :: (State.t -> state_stream_t)

@doc"""
Perform the unification.
"""
@spec eqo(value_t, value_t) :: goal_t
def eqo(u, v) do
  fn state ->
    s = unify(Map.get(state, :substitution), u, v)
    if s do
      [%State{state | substitution: s}]
    else
      []
    end
  end
end

@doc"""
Infix version of `eqo/2`.

          The Law of <~>
    v <~> w  is the same as  w <~> v.
"""
@spec value_t <~> value_t :: goal_t
def x <~> y do
  eqo(x, y)
end

@spec call_with_fresh((Var.t -> goal_t)) :: goal_t
def call_with_fresh(fun) do
  fn state ->
    id = Map.get(state, :id_counter)
    goal = fun.(Var.c(id))
    goal.(%State{state | id_counter: id+1})
  end
end

@spec disj(goal_t, goal_t) :: goal_t
def disj(g1, g2) do
  fn state ->
    s1 = g1.(state)
    s2 = g2.(state)
    mplus(s1, s2)
  end
end

@spec conj(goal_t, goal_t) :: goal_t
def conj(g1, g2) do
  fn state ->
    s1 = g1.(state)
    bind(s1, g2)
  end
end

@spec mplus(state_stream_t, state_stream_t) :: state_stream_t
def mplus(s1, s2) do
  case s1 do
    [] -> s2

    trunk when is_function(trunk) ->
      # - to use interleaving :
      #   to implement a complete search strategy
      #   ><><>< maybe we can use actor model to parallelize this
      # fn -> mplus(s2, trunk.()) end
      # - no interleaving :
      fn -> mplus(trunk.(), s2) end

    [head | tail] -> [head | mplus(tail, s2)]
  end
end

@spec bind(state_stream_t, goal_t) :: state_stream_t
def bind(s, g) do
  case s do
    [] -> []

    trunk when is_function(trunk) ->
      fn -> bind(trunk.(), g) end

    [head | tail] -> mplus(g.(head), bind(tail, g))
  end
end

@doc"""
Invers-η-delay

The act of performing an inverse-η on a goal
and then wrapping its body in a lambda
we refer to as inverse-η-delay.

Invers-η-delay is an operation that
takes a goal and returns a goal,
as the result of doing so on any goal g
is a function from a state to a stream.
"""
defmacro zzz(g) do
  quote do
    fn state ->
      fn ->
        unquote(g).(state)
      end
    end
  end
end

@doc"""
A macro for `conj/2` -- the logic and.

Example macro expanding :

    ando do
      g1
      g2
      g3
    end

    # = expand to =>

    conj(zzz(g1),
      conj(zzz(g2),
        zzz(g3)))
"""
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

@doc"""
A macro for `disj/2` -- the logic or.

Just like `ando/1`.
"""
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

@doc"""
A macro to create fresh logic variables.

          The Law of Fresh
    If x is fresh, then  v <~> x  succeeds
    and associates x with v.

Example macro expanding :

    fresh [a, b, c] do
      g1
      g2
      g3
    end

    # = expand to =>

    call_with_fresh fn a ->
      call_with_fresh fn b ->
        call_with_fresh fn c ->
          ando do
            g1
            g2
            g3
          end
        end
      end
    end
"""
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

@doc"""
A macro for a list `ando/1` in `oro/1`.

          The Law of conde
    To get more values from conde ,
    pretend that the successful conde
    line has failed, refreshing all variables
    that got an association from that line.

- conde is written conde and is pronounced “con-dee”.

- conde is the default control mechanism of Prolog.
  See William F. Clocksin. Clause and Effect. Springer, 1997.
"""
defmacro conde(exp) do
  case exp do
    [do: {:__block__, _, list}] ->
      quote do
        conde(unquote(list))
      end

    [do: single] ->
      quote do
        conde(unquote([single]))
      end

    [exp_list | []] ->
      quote do
        ando(unquote(exp_list))
      end

    [exp_list | tail] ->
      quote do
        disj(zzz(ando(unquote(exp_list))), conde(unquote(tail)))
      end
  end
end

@spec pull(state_stream_t) :: state_stream_t
def pull(state_stream) do
  if is_function(state_stream) do
    pull(state_stream.())
  else
    state_stream
  end
end

@spec take_all(state_stream_t) :: [State.t]
def take_all(state_stream) do
  state_stream = pull(state_stream)
  case state_stream do
    [] -> []
    [head | tail] -> [head | take_all(tail)]
  end
end

@spec take(state_stream_t, non_neg_integer) :: [State.t]
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

@spec mk_reify([State.t]) :: [value_t]
def mk_reify(state_list) do
  Enum.map(state_list, &reify_state_with_1st_var/1)
end

@spec reify_state_with_1st_var(State.t) :: value_t
def reify_state_with_1st_var(state) do
  s = Map.get(state, :substitution)
  v = deep_walk(Var.c(0), s)
  deep_walk(v, reify_s(v, Map.new()))
end

@spec deep_walk(value_t, substitution_t) :: value_t
def deep_walk(v, s) do
  v = walk(v, s)
  case v do
    %Var{} -> v

    [head | tail] -> [deep_walk(head, s) | deep_walk(tail, s)]

    _ ->
      cond do
        is_tuple(v) ->
          v
          |> Tuple.to_list()
          |> deep_walk(s)
          |> List.to_tuple()

        is_map(v) && not Var.p(v) ->
          v
          |> Map.to_list()
          |> deep_walk(s)
          |> Enum.into(Map.new())

        true -> v
      end
  end
end

@spec reify_s(value_t, substitution_t) :: substitution_t
def reify_s(v, s) do
  v = walk(v, s)
  nv = normalize_value(v)
  case nv do
    %Var{} -> Map.put(s, v, reify_name(length(Map.keys(s))))
    [head | tail] -> reify_s(tail, reify_s(head, s))
    _ -> s
  end
end

@spec reify_name(integer) :: atom
def reify_name(n) do
  n
  |> Integer.to_string()
  |> (fn s -> "_" <> s end).()
  |> String.to_atom()
end

@spec call_with_empty_state(goal_t) :: state_stream_t
def call_with_empty_state(goal) do
  goal.(empty_state())
end

defmacro run(n, var, exp) do
  quote do
    fresh(unquote(var), unquote(exp))
    |> call_with_empty_state()
    |> take(unquote(n))
    |> mk_reify()
  end
end

defmacro run(var, exp) do
  quote do
    fresh(unquote(var), unquote(exp))
    |> call_with_empty_state()
    |> take_all()
    |> mk_reify()
  end
end

@doc"""
A goal that succeeds.
"""
def succeed do
  fn state -> [state] end
end

@doc"""
A goal that fails.
"""
def fail do
  fn _state -> [] end
end

end
