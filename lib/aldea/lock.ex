defmodule Aldea.Lock do
  @moduledoc """
  A module for encoding and decoding Aldea's built-in lock types.
  """
  require Record
  alias Aldea.BCS
  import Aldea.Encoding, only: [bin_decode: 2, bin_encode: 2]

  @behaviour BCS.Encodable

  Record.defrecord(:lock, type: nil, data: nil)

  defguard is_lock(input) when Record.is_record(input, :lock)

  @typedoc """
  Defines different types of locks.
  """
  @type t() ::
    frozen_lock() |
    no_lock() |
    address_lock() |
    jig_lock() |
    public_lock()

  @type frozen_lock() :: record(:lock, type: :FROZEN, data: <<>>)
  @type no_lock() :: record(:lock, type: :UNLOCKED, data: <<>>)
  @type address_lock() :: record(:lock, type: :ADDRESS, data: <<_::160>>)
  @type jig_lock() :: record(:lock, type: :JIG, data: <<_::272>>)
  @type public_lock() :: record(:lock, type: :PUBLIC, data: <<>>)

  @lock_types %{
    FROZEN: -1,
    UNLOCKED: 0,
    ADDRESS: 1,
    JIG: 2,
    PUBLIC: 3,
  }

  @doc """
  Returns the map of all lock types.
  """
  @spec lock_types() :: map()
  def lock_types(), do: @lock_types

  @doc """
  Finds the lock type by key if it's an atom or by byte if it's an integer.
  """
  @spec find_lock_type(atom() | non_neg_integer()) :: {atom(), non_neg_integer()} | {:error, term}
  def find_lock_type(key) when is_atom(key),
    do: Enum.find(@lock_types, {:error, :unknown_lock_type}, fn {k, _v} -> k == key end)
  def find_lock_type(byte) when is_integer(byte),
    do: Enum.find(@lock_types, {:error, :unknown_lock_type}, fn {_k, v} -> v == byte end)

  @doc """
  Converts a binary data to an lock record.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  @spec from_bin(binary(), atom()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin, encoding \\ nil) when is_binary(bin) do
    with {:ok, bin} <- bin_decode(bin, encoding),
         {:ok, lock, <<>>} <- bcs_read(bin)
    do
      {:ok, lock}
    end
  end

  @doc """
  Converts a lock record to binary data.
  """
  @spec to_bin(t()) :: binary()
  @spec to_bin(t(), atom()) :: binary()
  def to_bin(lock, encoding \\ nil) when is_lock(lock),
    do: bcs_write(<<>>, lock) |> bin_encode(encoding)

  @doc """
  Reads the BCS data and returns a lock record.
  """
  @impl true
  def bcs_read(data) when is_binary(data) do
    with {:ok, byte, data} <- BCS.read(data, :i8),
         {lock_type, ^byte} <- find_lock_type(byte),
         {:ok, lock_data, rest} <- BCS.read(data, lock_data_schema(lock_type))
    do
      {:ok, lock(type: lock_type, data: lock_data), rest}
    end
  end

  @doc """
  Writes the lock data to BCS.
  """
  @impl true
  def bcs_write(data, {:lock, type, lock_data}) when is_binary(data) do
    data
    |> BCS.write(@lock_types[type], :i8)
    |> BCS.write(lock_data, lock_data_schema(type))
  end

  # Returns the lock data schema for the given lock type.
  defp lock_data_schema(:ADDRESS), do: {:bin, 20}
  defp lock_data_schema(:JIG), do: {:bin, 34}
  defp lock_data_schema(_), do: {:bin, 0}

end
