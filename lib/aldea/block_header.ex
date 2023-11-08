defmodule Aldea.BlockHeader do
  @moduledoc """
  TODO
  """
  require Aldea.BCS
  alias Aldea.BCS
  import Aldea.Encoding, only: [
    bin_decode: 2,
    bin_encode: 2,
  ]

  defstruct [:prev_block_id, :creator, :created_at, :tx_root, :state_root, :state_commit, :sig]
  BCS.defschema prev_block_id: {:bin, 32},
                creator: {:bin, 32},
                created_at: :u64,
                tx_root: {:bin, 32},
                state_root: {:bin, 32},
                state_commit: {:bin, 32},
                sig: {:bin, 64}

  @typedoc "BlockHeader"
  @type t() :: %__MODULE__{
    prev_block_id: <<_::256>>,
    creator: <<_::256>>,
    created_at: non_neg_integer(),
    tx_root: <<_::256>>,
    state_root: <<_::256>>,
    state_commit: <<_::256>>,
    sig: <<_::512>>,
  }

  @doc """
  Returns a Block from the given binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) do
    with {:ok, block, <<>>} <- bcs_read(bin), do: {:ok, block}
  end

  @doc """
  Returns a Block from the given hex-encoded string.
  """
  @spec from_hex(String.t()) :: {:ok, t()} | {:error, term()}
  def from_hex(hex) when is_binary(hex) do
    with {:ok, bin} <- bin_decode(hex, :hex), do: from_bin(bin)
  end

  @doc """
  Returns the ID (hex-encoded hash) of the block.
  """
  @spec get_id(t()) :: String.t()
  def get_id(%__MODULE__{} = block), do: get_hash(block) |> bin_encode(:hex)

  @doc """
  Returns the block hash.
  """
  @spec get_hash(t()) :: binary()
  def get_hash(%__MODULE__{} = block), do: to_bin(block) |> B3.hash()

  @doc """
  Returns the Block as a 232-byte binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{} = block), do: bcs_write(<<>>, block)

  @doc """
  Returns the Block as a hex-encoded string.
  """
  @spec to_hex(t()) :: String.t()
  def to_hex(%__MODULE__{} = block), do: to_bin(block) |> bin_encode(:hex)

end
