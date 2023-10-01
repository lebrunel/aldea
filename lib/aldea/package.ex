defmodule Aldea.Package do
  @moduledoc """
  A Package is a bundle of source code deployed on the Aldea computer. A package
  contains a map of code where the keys are paths and the values are
  source code. The package also has a list of one or more paths which are the
  entry files.
  """
  alias Aldea.BCS
  require BCS

  defstruct entry: [], code: %{}
  BCS.defschema entry: {:seq, :bin}, code: {:map, {:bin, :bin}}

  @typedoc "Package"
  @type t() :: %__MODULE__{
    entry: list(String.t()),
    code: %{
      optional(String.t()) => String.t()
    }
  }

  @doc """
  Returns a Package from the given binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) do
    with {:ok, pkg, <<>>} <- bcs_read(bin), do: {:ok, pkg}
  end

  @doc """
  Returns the Package as a binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{} = pkg), do: bcs_write(<<>>, pkg)

end
