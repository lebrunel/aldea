defmodule Aldea.KeyPair do
  @moduledoc """
  This module provides functionality related to a KeyPair, which contains a
  Private Key and its corresponding Public Key.
  """
  alias Aldea.{PrivKey, PubKey}

  defstruct [:privkey, :pubkey]

  @typedoc """
  Type representing a Key Pair.
  """
  @type t() :: %__MODULE__{
    privkey: PrivKey.t(),
    pubkey: PubKey.t(),
  }

  @doc """
  Generates a new random KeyPair in a secure manner.

  ## Examples

      iex> Aldea.KeyPair.generate_key()
      %Aldea.KeyPair{privkey: %Aldea.PrivKey{}, pubkey: %Aldea.PubKey{}}
  """
  @spec generate_key() :: t()
  def generate_key() do
    from_privkey(PrivKey.generate_key())
  end

  @doc """
  Constructs a KeyPair from the provided Private Key.
  """
  @spec from_privkey(PrivKey.t()) :: t()
  def from_privkey(%PrivKey{} = privkey) do
    pubkey = PubKey.from_privkey(privkey)
    struct(__MODULE__, privkey: privkey, pubkey: pubkey)
  end

end
