defmodule Exo.MixProject do
  use Mix.Project

  def project do
    [
      app: :exo,
      name: "Exo",
      version: "0.1.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      source_url: "https://github.com/xieyuheng/exo",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Logic programming in elixir.
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp package do
    [
      maintainers: ["xieyuheng"],
      licenses: ["GPLv3"],
      links: %{"GitHub" => "https://github.com/xieyuheng/exo"}
    ]
  end
end
