defmodule Aldea.MixProject do
  use Mix.Project

  def project do
    [
      app: :aldea,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:b3, "~> 0.1"},
      {:eddy, "~> 1.0"},
      {:ex_bech32, "~> 0.5"},
      {:ex_doc, "~> 0.30"},
      {:jason, "~> 1.4"},
      {:recase, "~> 0.7"},
    ]
  end
end
