defmodule Exo.MixProject do
  use Mix.Project

  def project do
    [
      app: :exo,
      version: "0.1.2",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/xieyuheng/exo",
      name: "Exo",
      docs: [
        main: "intro",
        extra_section: "DOCS",
        extras: extras()
      ],
      package: package(),
      deps: deps()
    ]
  end

  defp extras do
    [
      "docs/intro.md"
    ]
  end

  defp package do
    [
      description: "Logic programming in elixir.",
      maintainers: ["xieyuheng"],
      licenses: ["GPLv3"],
      links: %{"GitHub" => "https://github.com/xieyuheng/exo"}
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

end
