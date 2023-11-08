defmodule Aldea.Tx do
  @moduledoc """
  This module handles transactions in the Aldea system.

  A transaction is simply a list of instructions. When a transaction is
  processed, the instructions are executed in the order they appear in the
  transaction.
  """
  require Aldea.BCS
  import Aldea.Encoding, only: [bin_decode: 2, bin_encode: 2]
  alias Aldea.{BCS, Instruction}

  defstruct version: 1, instructions: []

  BCS.defschema version: :u16,
                instructions: {:seq, {:mod, Instruction}}

  @typedoc """
  Defines the structure of a transaction.
  """
  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    instructions: list(Instruction.t())
  }

  @doc """
  Decodes a binary to a transaction. Supports optional encoding formats `:hex`
  or `:base64`.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  @spec from_bin(binary(), atom()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin, encoding \\ nil) when is_binary(bin) do
    with {:ok, bin} <- bin_decode(bin, encoding),
         {:ok, instruction, <<>>} <- bcs_read(bin)
    do
      {:ok, instruction}
    end
  end

  @doc """
  Computes the transaction ID (hex-encoded hash) of the transaction.
  """
  @spec get_id(t()) :: String.t()
  def get_id(%__MODULE__{} = tx), do: get_hash(tx) |> bin_encode(:hex)

  @doc """
  Calculates the transaction hash.
  """
  @spec get_hash(t()) :: binary()
  def get_hash(%__MODULE__{} = tx), do: to_bin(tx) |> B3.hash()

  @doc """
  Computes the sighash of the current transaction. Can optionally be passed an
  index to return the sighash upto a given instruction.
  """
  @spec sighash(t(), integer()) :: binary()
  def sighash(%__MODULE__{} = tx), do: sighash(tx, length(tx.instructions))
  def sighash(%__MODULE__{} = tx, to) when is_integer(to) and to >= -1 do
    preimage = tx.instructions
    |> Enum.slice(0..to-1)
    |> Enum.reduce(<<>>, fn instruction, data ->
      case instruction do
        {op, _sig, pubkey} when op in [:SIGN, :SIGNTO] ->
          data
          |> BCS.write(Instruction.op_codes[op], :u8)
          |> BCS.write(pubkey, {:bin, 32})

        instruction ->
          Instruction.bcs_write(data, instruction)
      end
    end)

    B3.hash(preimage)
  end

  @doc """
  Encodes the transaction as a binary. Supports optional encoding formats
  `:hex` or `:base64`.
  """
  @spec to_bin(t()) :: binary()
  @spec to_bin(t(), atom()) :: binary()
  def to_bin(%__MODULE__{} = tx, encoding \\ nil),
    do: bcs_write(<<>>, tx) |> bin_encode(encoding)

  @doc """
  Verifies all SIGN and SIGNTO instructions in the transaction.
  """
  @spec verify(t()) :: boolean()
  def verify(%__MODULE__{} = tx) do
    tx.instructions
    |> Enum.with_index()
    |> Enum.all?(fn {instruction, i} ->
      case instruction do
        {:SIGN, sig, pubkey} -> Eddy.verify(sig, sighash(tx), pubkey)
        {:SIGNTO, sig, pubkey} -> Eddy.verify(sig, sighash(tx, i), pubkey)
        _ -> true
      end
    end)
  end

end
