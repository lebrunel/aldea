defmodule Aldea.BlockHeader do
  @moduledoc """
  This module represents the BlockHeader in the Aldea blockchain. It provides
  functions for encoding, decoding, and manipulating the BlockHeader.
  """
  require Aldea.BCS
  alias Aldea.BCS
  import Aldea.Encoding, only: [
    bin_decode: 2,
    bin_encode: 2,
  ]

  defstruct [:height, :prev_block_id, :creator, :created_at, :tx_root, :state_root, :state_commit, :sig]
  BCS.defschema height: :u64,
                prev_block_id: {:bin, 32},
                creator: {:bin, 32},
                created_at: :u64,
                tx_root: {:bin, 32},
                state_root: {:bin, 32},
                state_commit: {:bin, 32},
                sig: {:bin, 64}

  @typedoc """
  Type representing the BlockHeader.
  """
  @type t() :: %__MODULE__{
    height: non_neg_integer(),
    prev_block_id: <<_::256>>,
    creator: <<_::256>>,
    created_at: non_neg_integer(),
    tx_root: <<_::256>>,
    state_root: <<_::256>>,
    state_commit: <<_::256>>,
    sig: <<_::512>>,
  }

  @doc """
  Decodes a binary representation of a block. Supports optional encoding formats
  `:hex` or `:base64`.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  @spec from_bin(binary(), atom()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin, encoding \\ nil) do
    with {:ok, bin} <- bin_decode(bin, encoding),
         {:ok, block, <<>>} <- bcs_read(bin)
    do
      {:ok, block}
    end
  end

  @doc """
  Computes and returns the ID of the block, which is the hex-encoded hash of the
  block.
  """
  @spec get_id(t()) :: String.t()
  def get_id(%__MODULE__{} = block), do: get_hash(block) |> bin_encode(:hex)

  @doc """
  Computes and returns the hash of the block.
  """
  @spec get_hash(t()) :: binary()
  def get_hash(%__MODULE__{} = block), do: to_bin(block) |> B3.hash()

  @doc """
  Encodes the block into a binary representation. Supports optional encoding
  formats `:hex` or `:base64`.
  """
  @spec to_bin(t()) :: binary()
  @spec to_bin(t(), atom()) :: binary()
  def to_bin(%__MODULE__{} = block, encoding \\ nil),
    do: bcs_write(<<>>, block) |> bin_encode(encoding)

end
