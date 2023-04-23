defmodule Aldea.Encoding do
  @moduledoc """
  Support module with helper functions for encoding binary data to and from
  various encoding formats used in Aldea.
  """
  alias Aldea.Serializable

  @max_int64 18_446_744_073_709_551_615

  @doc """
  Decodes the given binary with bech32m.
  """
  @spec b32_decode(binary(), String.t()) :: {:ok, binary()} | {:error, term()}
  def b32_decode(str, prefix) do
    with {:ok, {^prefix, data, :bech32m}} <- ExBech32.decode(str) do
      {:ok, data}
    end
  end

  @doc """
  Encodes the given binary with bech32m.
  """
  @spec b32_encode(binary(), String.t()) :: String.t()
  def b32_encode(data, prefix) do
    with {:ok, str} <- ExBech32.encode(prefix, data, :bech32m), do: str
  end

  @doc """
  Decodes the given binary with the specified encoding scheme.
  """
  @spec bin_decode(binary(), atom()) :: {:ok, binary()} | {:error, term()}
  def bin_decode(data, encoding)
  def bin_decode(data, :base16), do: Base.decode16(data)
  def bin_decode(data, :base64), do: Base.decode64(data)
  def bin_decode(data, :hex), do: Base.decode16(data, case: :lower)
  def bin_decode(data, _), do: {:ok, data}

  @doc """
  Encodes the given binary with the specified encoding scheme.
  """
  @spec bin_encode(binary(), atom()) :: binary()
  def bin_encode(data, encoding)
  def bin_encode(data, :base16), do: Base.encode16(data)
  def bin_encode(data, :base64), do: Base.encode64(data)
  def bin_encode(data, :hex), do: Base.encode16(data, case: :lower)
  def bin_encode(data, _), do: data

  @doc """
  Decodes the given cbor-encoded binary sequence.
  """
  @spec cbor_seq_decode(binary()) :: {:ok, list(any())} | {:error, term()}
  def cbor_seq_decode(data), do: do_cbor_seq_decode(data)

  # Decodes the next item in the cbor sequence.
  @spec do_cbor_seq_decode(binary(), list(any())) :: {:ok, list(any())} | {:error, term()}
  defp do_cbor_seq_decode(data, items \\ [])
  defp do_cbor_seq_decode(<<>>, items), do: {:ok, Enum.reverse(items)}
  defp do_cbor_seq_decode(data, items) do
    with {:ok, item, rest} <- CBOR.decode(data) do
      do_cbor_seq_decode(rest, [item | items])
    end
  end

  @doc """
  Encodes the given list of items as a cbor sequence.
  """
  @spec cbor_seq_encode(list(any())) :: binary()
  def cbor_seq_encode(items) when is_list(items) do
    Enum.reduce(items, <<>>, & &2 <> CBOR.encode(&1))
  end

  @doc """
  Decodes the given varint-encoded binary as an integer.
  """
  @spec varint_decode(binary()) :: {:ok, integer()} | {:error, term()}
  def varint_decode(data) when is_binary(data) do
    with {:ok, int, _rest} <- varint_parse(data), do: {:ok, int}
  end

  @doc """
  Encodes the given integer as a varint-encoded binary.
  """
  @spec varint_encode(integer()) :: binary()
  def varint_encode(int)
    when is_integer(int)
    and int >= 0
    and int <= @max_int64
  do
    case int do
      int when int < 254 -> <<int::integer>>
      int when int < 0x10000 -> <<253, int::little-16>>
      int when int < 0x100000000 -> <<254, int::little-32>>
      int -> <<255, int::little-64>>
    end
  end

  @doc """
  Parses a varint from the given binary.
  """
  @spec varint_parse(binary()) :: {:ok, integer(), binary()} | {:error, term()}
  def varint_parse(<<253, int::little-16, rest::binary>>), do: {:ok, int, rest}
  def varint_parse(<<254, int::little-32, rest::binary>>), do: {:ok, int, rest}
  def varint_parse(<<255, int::little-64, rest::binary>>), do: {:ok, int, rest}
  def varint_parse(<<int::integer, rest::binary>>), do: {:ok, int, rest}
  def varint_parse(<<_data::binary>>), do: {:error, :invalid_varint}

  @doc """
  Parses a binary of a varint-encoded length from the given binary.
  """
  @spec varint_parse_data(binary()) :: {:ok, binary(), binary()} | {:error, term()}
  def varint_parse_data(<<253, int::little-16, data::bytes-size(int), rest::binary>>),
    do: {:ok, data, rest}
  def varint_parse_data(<<254, int::little-32, data::bytes-size(int), rest::binary>>),
    do: {:ok, data, rest}
  def varint_parse_data(<<255, int::little-64, data::bytes-size(int), rest::binary>>),
    do: {:ok, data, rest}
  def varint_parse_data(<<int::integer, data::bytes-size(int), rest::binary>>),
    do: {:ok, data, rest}
  def varint_parse_data(<<_data::binary>>),
    do: {:error, :invalid_varint}

  @doc """
  Parses a list of structs of a varint-encoded length from the given binary.
  """
  @spec varint_parse_structs(binary(), module()) ::
    {:ok, list(Serializable.t()), binary()} |
    {:error, term()}
  def varint_parse_structs(data, mod) when is_binary(data) and is_atom(mod) do
    with {:ok, int, data} <- varint_parse(data) do
      varint_parse_structs(data, int, mod)
    end
  end

  # Parses the next struct in the binary data.
  @spec varint_parse_structs(binary(), non_neg_integer(), module()) ::
    {:ok, list(Serializable.t()), binary()} |
    {:error, term()}
  defp varint_parse_structs(data, num, mod, result \\ [])

  defp varint_parse_structs(data, num, _mod, result)
    when length(result) == num,
    do: {:ok, Enum.reverse(result), data}

  defp varint_parse_structs(data, num, mod, result) do
    with {:ok, item, data} <- Serializable.parse(struct(mod), data) do
      varint_parse_structs(data, num, mod, [item | result])
    end
  end

end
