defmodule Aldea.Pointer do
  @moduledoc """
  An Aldea Pointer consists of a 32-btye ID and an index integer which points to
  the location of an object within a large data structure.

  A Pointer is encoded as a string by concatentating the hex encoded ID with the
  index.

  Example:

      3b2af88dad7f1847f5b333852b71ac6fd2ae519ba2d359e8ce07b071aad30e80_1
  """
  alias Aldea.BCS
  import Aldea.Encoding, only: [bin_decode: 2, bin_encode: 2]
  require BCS

  defstruct [:id, :idx]
  BCS.defschema id: {:bin, 32}, idx: :u16

  @typedoc "Pointer"
  @type t() :: %__MODULE__{
    id: <<_::256>>,
    idx: non_neg_integer(),
  }

  @doc """
  Returns a Pointer from the given 34-byte binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) do
    with {:ok, pointer, <<>>} <- bcs_read(bin), do: {:ok, pointer}
  end

  @doc """
  Returns a Pointer from the given hex-encoded string.
  """
  @spec from_hex(String.t()) :: {:ok, t()} | {:error, term()}
  def from_hex(hex) when is_binary(hex) do
    with {:ok, bin} <- bin_decode(hex, :hex), do: from_bin(bin)
  end

  @doc """
  Returns a PrivKey from the given string.
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
  Returns the Pointer as a 34-byte binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{} = ptr), do: bcs_write(<<>>, ptr)

  @doc """
  Returns the Pointer as a hex-encoded string.
  """
  @spec to_hex(t()) :: String.t()
  def to_hex(%__MODULE__{} = ptr), do: to_bin(ptr) |> bin_encode(:hex)

  @doc """
  Returns the Pointer as a bech32m-encoded string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{id: id, idx: idx}), do: "#{bin_encode(id, :hex)}_#{idx}"

end
