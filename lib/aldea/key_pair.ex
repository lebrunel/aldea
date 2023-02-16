defmodule Aldea.KeyPair do
  @moduledoc """
  A KeyPair contains a Private Key and it's corresponding Public Key.
  """
  alias Aldea.{PrivKey, PubKey}

  defstruct [:privkey, :pubkey]

  @typedoc "Key Pair"
  @type t() :: %__MODULE__{
    privkey: PrivKey.t(),
    pubkey: PubKey.t(),
  }

  @doc """
  Securely generates a new random KeyPair.
  """
  @spec generate_key() :: t()
  def generate_key() do
    from_privkey(PrivKey.generate_key())
  end

  @doc """
  Returns a KeyPair from the given PrivKey.
  """
  @spec from_privkey(PrivKey.t()) :: t()
  def from_privkey(%PrivKey{} = privkey) do
    pubkey = PubKey.from_privkey(privkey)
    struct(__MODULE__, privkey: privkey, pubkey: pubkey)
  end

end
