defmodule Aldea.PubKey do
  @moduledoc """
  A Public Key represents a point (X and Y coordinates) on the Ed25519 curve.
  A Public Key is derived from a corresponding PrivKey.

  PubKeys are serialized as the 32-byte Y coordinate, with the last byte
  encoding the sign of X.
  """
  alias Aldea.PrivKey
  import Aldea.Encoding, only: [
    b32_decode: 2, b32_encode: 2,
    bin_decode: 2, bin_encode: 2,
  ]

  defstruct [:point]

  @typedoc "Public Key"
  @type t() :: %__MODULE__{
    point: Eddy.Point.t()
  }

  @bech32_prefix %{
    main: "apub",
    test: "apub_test"
  }

  @doc """
  Returns a PubKey from the given PrivKey.
  """
  @spec from_privkey(PrivKey.t()) :: t()
  def from_privkey(%PrivKey{d: d}) do
    %{point: point} = Eddy.get_pubkey(d)
    struct(__MODULE__, point: point)
  end

  @doc """
  Returns a PubKey from the given 32-byte binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) when is_binary(bin) do
    with {:ok, %{point: point}} <- Eddy.PubKey.from_bin(bin) do
      {:ok, struct(__MODULE__, point: point)}
    end
  end

  @doc """
  Returns a PubKey from the given hex-encoded string.
  """
  @spec from_hex(String.t()) :: {:ok, t()} | {:error, term()}
  def from_hex(hex) when is_binary(hex) do
    with {:ok, bin} <- bin_decode(hex, :hex), do: from_bin(bin)
  end

  @doc """
  Returns a PubKey from the given bech32m-encoded string.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, term()}
  def from_string(str) when is_binary(str) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    with {:ok, bin} <- b32_decode(str, prefix), do: from_bin(bin)
  end

  @doc """
  Returns the PubKey as a 32-byte binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{point: point}),
    do: Eddy.Serializable.Encoder.serialize(point)

  @doc """
  Returns the PubKey as a hex-encoded string.
  """
  @spec to_hex(t()) :: String.t()
  def to_hex(%__MODULE__{} = pubkey), do: to_bin(pubkey) |> bin_encode(:hex)

  @doc """
  Returns the PubKey as a bech32m-encoded string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = pubkey) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    b32_encode(to_bin(pubkey), prefix)
  end

end
