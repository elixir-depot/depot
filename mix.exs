defmodule Depot.MixProject do
  use Mix.Project

  def project do
    [
      app: :depot,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      deps: deps(),
      name: "Postgrex",
      source_url: "https://github.com/elixir-ecto/postgrex"
    ]
  end

  defp description() do
    "A filesystem abstraction for elixir."
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
      {
        :briefly,
        git: "https://github.com/CargoSense/briefly", ref: "06ac1a6", only: :test
      }
    ]
  end
end
