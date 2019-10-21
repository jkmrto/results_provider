defmodule ResultsProvider.MixProject do
  use Mix.Project

  def project do
    [
      app: :results_provider,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ResultsProvider, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/results_provider/test_support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:nimble_csv, "~> 0.5.0"},
      {:distillery, "~> 2.0.0"},
      {:exprotobuf, "~> 1.2.9"},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end
end
