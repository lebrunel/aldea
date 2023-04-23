defmodule Aldea.Encoding do
  @moduledoc """
  TODO
  """
  alias Aldea.Serializable
  @max_int64 18_446_744_073_709_551_615

  @doc """
  TODO
  """
  @spec b32_decode(binary(), String.t()) :: {:ok, binary()} | {:error, term()}
  def b32_decode(str, prefix) do
    with {:ok, {^prefix, data, :bech32m}} <- ExBech32.decode(str) do
      {:ok, data}
    end
  end

  @doc """
  TODO
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
  TODO
  """
  @spec varint_decode(binary()) :: {:ok, integer()} | {:error, term()}
  def varint_decode(data) when is_binary(data) do
    with {:ok, int, _rest} <- varint_parse(data), do: {:ok, int}
  end

  @doc """
  TODO
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
  TODO
  """
  @spec varint_parse(binary()) :: {:ok, integer(), binary()} | {:error, term()}
  def varint_parse(<<253, int::little-16, rest::binary>>), do: {:ok, int, rest}
  def varint_parse(<<254, int::little-32, rest::binary>>), do: {:ok, int, rest}
  def varint_parse(<<255, int::little-64, rest::binary>>), do: {:ok, int, rest}
  def varint_parse(<<int::integer, rest::binary>>), do: {:ok, int, rest}
  def varint_parse(<<_data::binary>>), do: {:error, :invalid_varint}

  @doc """
  TODO
  """
  @spec varint_parse_structs(binary(), module()) ::
    {:ok, list(Serializable.t()), binary()} |
    {:error, term()}
  def varint_parse_structs(data, mod) when is_binary(data) and is_atom(mod) do
    with {:ok, int, data} <- varint_parse(data) do
      varint_parse_structs(data, int, mod)
    end
  end

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
