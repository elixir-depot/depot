defmodule Depot.MixProject do
  use Mix.Project

  def project do
    [
      app: :depot,
      version: "0.5.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      # Replace with ExUnit tmp_dir on 1.11
      {
        :briefly,
        git: "https://github.com/CargoSense/briefly", ref: "06ac1a6", only: :test
      }
    ]
  end
end
