defmodule Aldea.Encoding do
  @moduledoc """
  Support module with helper functions for encoding binary data to and from
  various encoding formats used in Aldea.
  """
  import Bitwise, only: [bor: 2, bsl: 2, bsr: 2]

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
  Decodes the given binary into an integer using ULEB.
  """
  @spec uleb_decode(binary()) :: {:ok, non_neg_integer()} | {:error, term()}
  def uleb_decode(data)  do
    with {:ok, int, _rest} <- uleb_parse(data), do: {:ok, int}
  end

  @doc """
  Encodes the given integer using ULEB.
  """
  @spec uleb_encode(non_neg_integer()) :: binary()
  def uleb_encode(int) when int < 128, do: <<int>>
  def uleb_encode(int), do: <<1::1, int::7, uleb_encode(bsr(int, 7))::binary>>

  @doc """
  Parses an integer from the given binary using ULEB.
  """
  @spec uleb_parse(binary()) :: {:ok, non_neg_integer(), binary()} | {:error, term()}
  def uleb_parse(data) when is_binary(data), do: uleb_parse(data, 0, 0)

  @spec uleb_parse(binary(), non_neg_integer(), non_neg_integer()) ::
    {:ok, non_neg_integer(), binary()} |
    {:error, term()}
  defp uleb_parse(<<0::1, byte::7, rest::binary>>, shift, result) do
    {:ok, bor(result, bsl(byte, shift)), rest}
  end

  defp uleb_parse(<<1::1, byte::7, rest::binary>>, shift, result) do
    uleb_parse(rest, shift + 7, bor(result, bsl(byte, shift)))
  end

end
