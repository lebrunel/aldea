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
      {:cbor, "~> 1.0"},
      {:eddy, path: "/Users/aaron/Dev/chronos/eddy"},
      {:ex_bech32, "~> 0.4"},
      {:jason, "~> 1.4"},
      {:mnemonic, "~> 0.3", only: :test},
    ]
  end
end
