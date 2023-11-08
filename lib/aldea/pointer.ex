defmodule Aldea.Pointer do
  @moduledoc """
  This module defines an Aldea Pointer which has a 32-byte ID and an index
  integer. A pointer points to the location of an object within a larger data
  structure. The Pointer is encoded as a string by concatenating the hex encoded
  ID with the index.

  Example:

  ```text
  3b2af88dad7f1847f5b333852b71ac6fd2ae519ba2d359e8ce07b071aad30e80_1
  ```
  """
  require Aldea.BCS
  import Aldea.Encoding, only: [bin_decode: 2, bin_encode: 2]
  alias Aldea.BCS

  defstruct [:id, :idx]
  BCS.defschema id: {:bin, 32}, idx: :u16

  @typedoc """
  Type representing a Pointer.
  """
  @type t() :: %__MODULE__{
    id: <<_::256>>,
    idx: non_neg_integer(),
  }

  @doc """
  Returns a Pointer from a given 34-byte binary. It supports optional
  encoding formats such as `:hex` or `:base64`.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  @spec from_bin(binary(), atom()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin, encoding \\ nil) do
    with {:ok, bin} <- bin_decode(bin, encoding),
         {:ok, pointer, <<>>} <- bcs_read(bin)
    do
      {:ok, pointer}
    end
  end

  @doc """
  returns a Pointer from a given string.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, term()}
  def from_string(str) when is_binary(str) do
    with [^str, id, idx] <- Regex.run(~r/^([a-f0-9]{64})_(\d+)$/, str),
         {:ok, id} <- bin_decode(id, :hex)
    do
      {:ok, struct(__MODULE__, id: id, idx: String.to_integer(idx))}
    else
      nil -> {:error, :invalid_format}
    end
  end

  @doc """
  Returns the hex-encoded Pointer ID.
  """
  @spec get_id(t()) :: String.t()
  def get_id(%__MODULE__{id: id}), do: bin_encode(id, :hex)

  @doc """
  Returns the Pointer as a 34-byte binary. It supports optional encoding formats
  such as `:hex` or `:base64`.
  """
  @spec to_bin(t()) :: binary()
  @spec to_bin(t(), atom()) :: binary()
  def to_bin(%__MODULE__{} = ptr, encoding \\ nil),
    do: bcs_write(<<>>, ptr) |> bin_encode(encoding)

  @doc """
  Returns the Pointer as a string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{id: id, idx: idx}),
    do: "#{bin_encode(id, :hex)}_#{idx}"

end
