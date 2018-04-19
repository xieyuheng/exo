defmodule TheReasoned do
  @moduledoc """
  The Reasoned Schemer in Elixir.
  """

  import Exo

  def cons(a, d) do
    [a | d]
  end

  def car(p) do
    hd(p)
  end

  def cdr(p) do
    tl(p)
  end

  def conso(a, d, p) do
    cons(a, d) <~> p
  end

  def caro(p, a) do
    fresh [d] do
      cons(a, d) <~> p
    end
  end

  def cdro(p, d) do
    fresh [a] do
      cons(a, d) <~> p
    end
  end

  def null?(x) do
    x === []
  end

  def nullo(x) do
    x <~> []
  end

  def pair?(p) do
    case p do
      [_ | _] -> true
      _ -> false
    end
  end

  def pairo(p) do
    fresh [a, d] do
      cons(a, d) <~> p
    end
  end

  def list?(l) do
    cond do
      null?(l) -> true
      pair?(l) -> list?(cdr(l))
      :else -> false
    end
  end

  #               The First Commandment
  #   To transform a function whose value is a boolean
  # into a function whose value is a goal, replace cond
  # with conde and unnest each question and answer.

  def listo(l) do
    oro do
      nullo(l)
      fresh [d] do
        pairo(l)
        cdro(l, d)
        listo(d)
      end
    end
  end

  def lol?(l) do
    cond do
      null?(l) -> true
      list?(car(l)) -> lol?(cdr(l))
      :else -> false
    end
  end

  def lolo(l) do
    oro do
      nullo(l)
      fresh [a, d] do
        caro(l, a)
        listo(a)
        cdro(l, d)
        lolo(d)
      end
    end
  end

  def twinso(s) do
    fresh [x] do
      [x, x] <~> s
    end
  end

  def loto(l) do
    oro do
      nullo(l)
      fresh [a, d] do
        caro(l, a)
        twinso(a)
        cdro(l, d)
        loto(d)
      end
    end
  end

  def listofo(predo, l) do
    oro do
      nullo(l)
      fresh [a, d] do
        caro(l, a)
        predo.(a)
        cdro(l, d)
        listofo(predo, d)
      end
    end
  end

  def appendo(l, s, out) do
    oro do
      ando do nullo(l); out <~> s end
      fresh [a, d, rec] do
        conso(a, d, l)
        appendo(d, s, rec)
        conso(a, rec, out)
      end
    end
  end

  def flatteno(s, out) do
    oro do
      ando do nullo(s)
        [] <~> out
      end
      ando do pairo(s)
        fresh [a, d, res_a, res_d] do
          conso(a, d, s)
          flatteno(a, res_a)
          flatteno(d, res_d)
          appendo(res_a, res_d, out)
        end
      end
      conso(s, [], out)
    end
  end

end
