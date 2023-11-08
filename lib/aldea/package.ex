defmodule Aldea.Package do
  @moduledoc """
  A module for handling Aldea packages.

  A Package is a bundle of source code deployed on the Aldea computer. It
  contains a map of code where the keys are paths and the values are source
  code. The package also has a list of one or more paths which are the entry
  files.
  """
  require Aldea.BCS
  import Aldea.Encoding, only: [bin_decode: 2, bin_encode: 2]
  alias Aldea.BCS

  defstruct entry: [], code: %{}
  BCS.defschema entry: {:seq, :bin}, code: {:map, {:bin, :bin}}

  @typedoc """
  Defines the package type.
  """
  @type t() :: %__MODULE__{
    entry: list(String.t()),
    code: %{
      optional(String.t()) => String.t()
    }
  }

  @doc """
  Converts a binary into a Package. Supports optional encoding formats `:hex` or
  `:base64`.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  @spec from_bin(binary(), atom()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin, encoding \\ nil) do
    with {:ok, bin} <- bin_decode(bin, encoding),
         {:ok, package, <<>>} <- bcs_read(bin)
    do
      {:ok, package}
    end
  end

  @doc """
  Converts a Package into a binary. Supports optional encoding formats `:hex` or
  `:base64`.
  """
  @spec to_bin(t()) :: binary()
  @spec to_bin(t(), atom()) :: binary()
  def to_bin(%__MODULE__{} = pkg, encoding \\ nil),
    do: bcs_write(<<>>, pkg) |> bin_encode(encoding)

end
