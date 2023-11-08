defmodule Aldea.Address do
  @moduledoc """
  This module handles Aldea addresses which are 20-byte BLAKE3 hashes of public
  keys. Addresses are encoded as strings using Bech32m and prefixed with `"addr"`.

  Example:

  ```text
  addr1hldfmuyecahs4c9uypz6w4rv04cpzf50a5rsfc
  ```
  """
  alias Aldea.PubKey
  import Aldea.Encoding, only: [b32_decode: 2, b32_encode: 2]

  defstruct [:hash]

  @typedoc """
  Type representing an Aldea address.
  """
  @type t() :: %__MODULE__{hash: <<_::160>>}

  @bech32_prefix %{
    main: "addr",
    test: "addr_test"
  }

  @doc """
  Generates an Aldea address from a Bech32m-encoded string.
  """
  @spec from_pubkey(PubKey.t()) :: t()
  def from_pubkey(%PubKey{} = pubkey) do
    hash = B3.hash(PubKey.to_bin(pubkey), length: 20)
    struct(__MODULE__, hash: hash)
  end

  @doc """
  Encodes an Aldea address into a string.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, term()}
  def from_string(str) when is_binary(str) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    with {:ok, hash} <- b32_decode(str, prefix) do
      {:ok, struct(__MODULE__, hash: hash)}
    end
  end

  @doc """
  Encodes the Address as a string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{hash: hash}) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    b32_encode(hash, prefix)
  end

end
