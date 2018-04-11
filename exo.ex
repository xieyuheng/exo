defmodule Exo do
  defmodule Var do
    defstruct id: nil
  end

  def var id do
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

  # def disj x, y do
  #   x + y
  # end
end

ExUnit.start

defmodule Exo.Text do
  use ExUnit.Case, async: true

  test "var" do
    assert Exo.var 0 |> Exo.var?
    assert Exo.var 1 |> Exo.var?
    assert Exo.var 2 |> Exo.var?
    assert Exo.var 0 === Exo.var 0
  end

  test "unify" do
    s = Exo.unify [:a, :b, :c], [:a, :b, :c], %{}
    assert s === %{}
    s = Exo.unify [[:a, :b, :c],
                   [:a, :b, :c],
                   [:a, :b, :c]],
      [[:a, :b, :c],
       [:a, :b, :c],
       [:a, :b, :c]], %{}
    assert s === %{}
    s = Exo.unify [Exo.var(0), :b, :c], [:a, :b, :c], %{}
    assert s === %{%Exo.Var{id: 0} => :a}
    s = Exo.unify [[Exo.var(0), :b, :c],
                   [:a, Exo.var(1), :c],
                   [:a, :b, Exo.var(2)]],
      [[:a, :b, :c],
       [:a, :b, :c],
       [:a, :b, :c]], %{}
    assert s === %{%Exo.Var{id: 0} => :a,
                   %Exo.Var{id: 1} => :b,
                   %Exo.Var{id: 2} => :c}
  end

  test "state" do
  end

  test "stream" do
  end
end
