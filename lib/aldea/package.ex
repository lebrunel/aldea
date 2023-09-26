defmodule Aldea.Package do
  @moduledoc """
  TODO
  """
  alias Aldea.BCS
  require BCS

  defstruct entry: [], code: %{}
  BCS.defschema entry: {:seq, :bin}, code: {:map, {:bin, :bin}}

  @type t() :: %__MODULE__{
    entry: list(String.t()),
    code: %{
      optional(String.t()) => String.t()
    }
  }

  @doc """
  TODO
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) do
    with {:ok, pkg, <<>>} <- bcs_read(bin) do
      {:ok, update_in(pkg.code, & Enum.into(&1, %{}))}
    end
  end

  @doc """
  Returns the Pointer as a 34-byte binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{} = pkg), do: bcs_write(<<>>, pkg)

end
