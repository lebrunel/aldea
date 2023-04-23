defmodule Aldea.Address do
  @moduledoc """
  An Aldea address is the 20-byte BLAKE3 hash of a public key. It is encoded as
  a string using Bech32m with the prefix `"addr"`.

  Example:

      addr1hldfmuyecahs4c9uypz6w4rv04cpzf50a5rsfc
  """
  alias Aldea.PubKey

  defstruct [:hash]

  @typedoc "Address"
  @type t() :: %__MODULE__{hash: <<_::160>>}

  @bech32_prefix %{
    main: "addr",
    test: "addr_test"
  }

  @doc """
  Returns an Address from the given PubKey.
  """
  @spec from_pubkey(PubKey.t()) :: t()
  def from_pubkey(%PubKey{} = pubkey) do
    hash = B3.hash(PubKey.to_bin(pubkey), length: 20)
    struct(__MODULE__, hash: hash)
  end

  @doc """
  Returns an Address from the bech32m-encoded string.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, term()}
  def from_string(str) when is_binary(str) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    with {:ok, {^prefix, hash, :bech32m}} <- ExBech32.decode(str) do
      {:ok, struct(__MODULE__, hash: hash)}
    end
  end

  @doc """
  Encodes the Address as a string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{hash: hash}) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    with {:ok, str} <- ExBech32.encode(prefix, hash, :bech32m) do
      str
    end
  end

end
