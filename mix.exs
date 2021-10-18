defmodule Depot.MixProject do
  use Mix.Project

  def project do
    [
      app: :depot,
      version: "0.5.2",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      name: "Depot",
      source_url: "https://github.com/elixir-depot/depot",
      docs: docs()
    ]
  end

  defp description() do
    "A filesystem abstraction for elixir."
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib  mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/elixir-depot/depot"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      groups_for_modules: [
        Stat: [
          ~r/^Depot\.Stat\./
        ],
        Adapters: [
          ~r/^Depot\.Adapter\./
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Depot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
