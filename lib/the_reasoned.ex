defmodule TheReasoned do
  @moduledoc """
  The Reasoned Schemer in Elixir.
  """

  import Exo

  def cons(a, d) do
    [a | d]
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

  def nullo(x) do
    x <~> []
  end

  def pairo(p) do
    fresh [a, d] do
      cons(a, d) <~> p
    end
  end

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
