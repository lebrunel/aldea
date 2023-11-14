defmodule Aldea.Output do
  @moduledoc """
  A module for handling Aldea transaction execution outputs.

  It provides functions for encoding, decoding, and reading the state of a given
  output.
  """
  require Aldea.BCS
  import Aldea.Encoding, only: [bin_decode: 2, bin_encode: 2]
  alias Aldea.{ABI, BCS, Lock, Pointer}

  defstruct [:origin, :location, :class, :lock, :state]
  BCS.defschema origin: {:mod, Pointer},
                location: {:mod, Pointer},
                class: {:mod, Pointer},
                lock: {:mod, Lock},
                state: :bin

  @typedoc """
  Type representing an Output.
  """
  @type t() :: %__MODULE__{
    origin: Pointer.t(),
    location: Pointer.t(),
    class: Pointer.t(),
    lock: Lock.t(),
    state: binary(),
  }

  @doc """
  Decodes the state of the given output using the corresponding ABI.
  """
  @spec decode_state(t(), ABI.t()) :: {:ok, t()} | {:error, term()}
  def decode_state(%__MODULE__{} = output, %ABI{} = abi) do
    %{name: name} = abi.exports
    |> Enum.map(& Enum.at(abi.defs, &1))
    |> Enum.at(output.class.idx)

    ABI.decode(abi, name, output.state)
  end

  @doc """
  Converts the given binary data to an output struct.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  @spec from_bin(binary(), atom()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin, encoding \\ nil) when is_binary(bin) do
    with {:ok, bin} <- bin_decode(bin, encoding),
         {:ok, output, <<>>} <- bcs_read(bin)
    do
      {:ok, output}
    end
  end

  @doc """
  Returns the ID of the given output.
  """
  @spec get_id(t()) :: String.t()
  def get_id(%__MODULE__{} = output), do: get_hash(output) |> bin_encode(:hex)

  @doc """
  Returns the hash of the given output.
  """
  @spec get_hash(t()) :: binary()
  def get_hash(%__MODULE__{} = output), do: to_bin(output) |> B3.hash()

  @doc """
  Converts the given output to binary.
  """
  @spec to_bin(t()) :: binary()
  @spec to_bin(t(), atom()) :: binary()
  def to_bin(%__MODULE__{} = output, encoding \\ nil),
    do: bcs_write(<<>>, output) |> bin_encode(encoding)

end
