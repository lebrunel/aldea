defmodule Aldea.PrivKey do
  @moduledoc """
  A module for handling Aldea private keys, which are random 32-byte binary
  values.
  """
  import Aldea.Encoding, only: [
    b32_decode: 2, b32_encode: 2,
    bin_decode: 2, bin_encode: 2,
  ]

  defstruct [:d]

  @typedoc """
  Type representing a Private Key.
  """
  @type t() :: %__MODULE__{d: <<_::256>>}

  @bech32_prefix %{
    main: "asec",
    test: "asec_test"
  }

  @doc """
  Generates a new private key securely and randomly.
  """
  @spec generate_key() :: t()
  def generate_key() do
    d = Eddy.generate_key(encoding: :bin)
    struct(__MODULE__, d: d)
  end

  @doc """
  Converts a given 32-byte binary into a private key. Supports optional encoding
  formats like `:hex` or `:base64`.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  @spec from_bin(binary(), atom()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin, encoding \\ nil) when is_binary(bin) do
    with {:ok, bin} <- bin_decode(bin, encoding) do
      case byte_size(bin) do
        32 -> {:ok, struct(__MODULE__, d: bin)}
        n -> {:error, {:invalid_length, n}}
      end
    end
  end

  @doc """
  Converts a given bech32m-encoded string into a private key.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, term()}
  def from_string(str) when is_binary(str) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    with {:ok, bin} <- b32_decode(str, prefix), do: from_bin(bin)
  end

  @doc """
  Converts a private key into a 32-byte binary. Supports optional encoding
  formats like `:hex` or `:base64`.
  """
  @spec to_bin(t()) :: binary()
  @spec to_bin(t(), atom()) :: binary()
  def to_bin(%__MODULE__{d: d}, encoding \\ nil),
    do: bin_encode(d, encoding)

  @doc """
  Converts a private key into a bech32m-encoded string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{d: d}) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    b32_encode(d, prefix)
  end

end
