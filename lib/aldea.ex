defmodule Aldea do
  @moduledoc """
  Documentation for `Aldea`.
  """

  @typedoc "Network identifier"
  @type network() :: :main | :test

  @version Mix.Project.config[:version]

  @doc """
  Returns the configured Aldea network. Defaults to `:main`.
  """
  @spec network() :: network()
  def network() do
    Application.get_env(:aldea, :network, :main)
  end

  @doc """
  Returns the version of the Aldea package.
  """
  @spec version() :: String.t
  def version(), do: @version

end
