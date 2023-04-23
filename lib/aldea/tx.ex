defmodule Aldea.Tx do
  @moduledoc """
  A transaction is simply a list of instructions. When a transaction is
  processed, the instructions are executed in the order they appear in the
  transaction.
  """
  alias Aldea.{
    Instruction,
    Serializable,
  }
  import Aldea.Encoding, only: [
    bin_decode: 2,
    bin_encode: 2,
    varint_encode: 1,
    varint_parse_structs: 2,
  ]

  defstruct version: 1, instructions: []

  @typedoc "Transaction"
  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    instructions: list(Instruction.t())
  }

  @doc """
  Returns a Tx from the given binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) when is_binary(bin) do
    with {:ok, instruction, <<>>} <- Serializable.parse(struct(__MODULE__), bin) do
      {:ok, instruction}
    end
  end

  @doc """
  Returns a Tx from the given hex-encoded string.
  """
  @spec from_hex(String.t()) :: {:ok, t()} | {:error, term()}
  def from_hex(hex) when is_binary(hex) do
    with {:ok, bin} <- bin_decode(hex, :hex), do: from_bin(bin)
  end

  @doc """
  Returns the transaction ID (hex-encoded hash) of the transaction.
  """
  @spec get_id(t()) :: String.t()
  def get_id(%__MODULE__{} = tx), do: get_hash(tx) |> bin_encode(:hex)

  @doc """
  Returns the transaction hash.
  """
  @spec get_hash(t()) :: binary()
  def get_hash(%__MODULE__{} = tx), do: to_bin(tx) |> B3.hash()

  @doc """
  Returns the sighash of the current transaction. Can optionally be passed
  an index to return the sighash upto a given instruction.
  """
  @spec sighash(t(), integer()) :: binary()
  def sighash(%__MODULE__{} = tx, to) when is_integer(to) and to >= -1 do
    tx.instructions
    |> Enum.slice(0..to)
    |> Enum.filter(& &1.op not in [:SIGN, :SIGNTO])
    |> Enum.reduce(<<>>, & &2 <> Serializable.serialize(&1))
    |> B3.hash()
  end

  @doc """
  Returns the Tx as a 32-byte binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{} = tx), do: Serializable.serialize(tx)

  @doc """
  Returns the Tx as a hex-encoded string.
  """
  @spec to_hex(t()) :: String.t()
  def to_hex(%__MODULE__{} = tx), do: to_bin(tx) |> bin_encode(:hex)


  defimpl Serializable do
    @impl true
    def parse(tx, <<version::little-16, data::binary>>) do
      with {:ok, instructions, rest} <- varint_parse_structs(data, Instruction) do
        {:ok, struct(tx, [version: version, instructions: instructions]), rest}
      end
    end

    @impl true
    def serialize(tx) do
      data = <<tx.version::little-16>> <> varint_encode(length(tx.instructions))
      Enum.reduce(tx.instructions, data, fn inst, bin ->
        bin <> Serializable.serialize(inst)
      end)
    end
  end

end
