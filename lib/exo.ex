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

  @type value :: atom | integer | String.t | Var.t | [value]
  @type substitution :: %{required(Var.t) => value}

  @doc"""
  One-step walking

  Walking until the value is not Var.t,
  which does not care about other vars in the result value.
  """
  @spec walk(value, substitution) :: value
  def walk(u, s) do
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

  @spec unify(substitution, value, value) :: substitution | false
  def unify(s, u, v) do
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
    State.c(0, %{})
  end

  @type state_stream ::
          maybe_improper_list(State.t, state_stream)
          | (-> state_stream)

  @type goal :: (State.t -> state_stream)

  @doc"""
  Perform the unification.
  """
  @spec eqo(value, value) :: goal
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
  Infix version of `eqo`.
  """
  @spec value <~> value :: goal
  def x <~> y do
    eqo(x, y)
  end

  @spec call_with_fresh((Var.t -> goal)) :: goal
  def call_with_fresh(fun) do
    fn state ->
      id = Map.get(state, :id_counter)
      goal = fun.(Var.c(id))
      goal.(%State{state | id_counter: id+1})
    end
  end

  @spec disj(goal, goal) :: goal
  def disj(g1, g2) do
    fn state ->
      s1 = g1.(state)
      s2 = g2.(state)
      mplus(s1, s2)
    end
  end

  @spec conj(goal, goal) :: goal
  def conj(g1, g2) do
    fn state ->
      s1 = g1.(state)
      bind(s1, g2)
    end
  end

  @spec mplus(state_stream, state_stream) :: state_stream
  def mplus(s1, s2) do
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

  @spec bind(state_stream, goal) :: state_stream
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
  A macro for conj -- the logic and.

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
  A macro for disj -- the logic or.

  Just like ando.

  - minikanren user should note that,
    we do no implement the conde macro of minikanren,
    we use oro instead.
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

  @spec pull(state_stream) :: state_stream
  def pull(state_stream) do
    if is_function(state_stream) do
      pull(state_stream.())
    else
      state_stream
    end
  end

  @spec take_all(state_stream) :: [State.t]
  def take_all(state_stream) do
    state_stream = pull(state_stream)
    case state_stream do
      [] -> []
      [head | tail] -> [head | take_all(tail)]
    end
  end

  @spec take(state_stream, non_neg_integer) :: [State.t]
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

  @spec mk_reify([State.t]) :: [value]
  def mk_reify(state_list) do
    Enum.map(state_list, &reify_state_with_1st_var/1)
  end

  @spec reify_state_with_1st_var(State.t) :: value
  def reify_state_with_1st_var(state) do
    s = Map.get(state, :substitution)
    v = deep_walk(Var.c(0), s)
    deep_walk(v, reify_s(v, []))
  end

  @spec deep_walk(value, substitution) :: value
  def deep_walk(v, s) do
    v = walk(v, s)
    case v do
      %Var{} -> v
      [head | tail] -> [deep_walk(head, s) | deep_walk(tail, s)]
      _ -> v
    end
  end

  @spec reify_s(value, substitution) :: substitution
  def reify_s(v, s) do
    # -> value, Substitution -- Substitution
    case v do
      %Var{} ->
        n = reify_name(length(s))
        [[v | n] | s]

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

  @spec call_with_empty_state(goal) :: state_stream
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

  defmacro run_all(var, exp) do
    quote do
      fresh(unquote(var), unquote(exp))
      |> call_with_empty_state()
      |> take_all()
      |> mk_reify()
    end
  end

end
