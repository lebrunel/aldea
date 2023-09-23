defmodule Aldea.HDPubKey do
  @moduledoc """
  TODO
  """
  alias Aldea.HDPubKey
  alias Aldea.{
    HDPrivKey,
    PubKey,
  }

  import Aldea.Encoding, only: [
    b32_decode: 2,
    b32_encode: 2,
    bin_decode: 2,
    bin_encode: 2,
  ]

  defstruct [:key_data, :chain_code]

  @typedoc "HD Private Key"
  @type t() :: %__MODULE__{
    key_data: <<_::256>>,
    chain_code: <<_::256>>,
  }

  @bech32_prefix %{
    main: "xpub",
    test: "xpub_test"
  }
  @hardened_offset 0x80000000

  @doc """
  TODO
  """
  @spec from_hd_privkey(HDPrivKey.t()) :: t()
  def from_hd_privkey(%HDPrivKey{chain_code: chain_code} = privkey) do
    key_data = HDPrivKey.get_pubkey_bytes(privkey)
    struct(__MODULE__, key_data: key_data, chain_code: chain_code)
  end

  @doc """
  Returns a HDPubKey from the given 64-byte binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) when is_binary(bin) do
    case bin do
      <<kd::binary-32, cc::binary-32>> ->
        {:ok, struct(__MODULE__, key_data: kd, chain_code: cc)}
      _ ->
        {:error, {:invalid_length, byte_size(bin)}}
    end
  end

  @doc """
  Returns a HDPrivKey from the given hex-encoded string.
  """
  @spec from_hex(String.t()) :: {:ok, t()} | {:error, term()}
  def from_hex(hex) when is_binary(hex) do
    with {:ok, bin} <- bin_decode(hex, :hex), do: from_bin(bin)
  end

  @doc """
  Returns a HDPrivKey from the given bech32m-encoded string.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, term()}
  def from_string(str) when is_binary(str) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    with {:ok, bin} <- b32_decode(str, prefix), do: from_bin(bin)
  end

  @doc """
  TODO
  """
  @spec get_pubkey_bytes(t()) :: binary()
  def get_pubkey_bytes(%__MODULE__{key_data: key_data}), do: key_data

  @doc """
  TODO
  """
  @spec derive(t(), String.t()) :: t()
  def derive(%__MODULE__{} = pubkey, path) when is_binary(path) do
    unless String.match?(path, ~r/^[mM]['hH]?(\/\d+['hH]?)+/) do
      raise "invalid derivation path"
    end

    path
    |> String.split("/")
    |> Enum.map(&to_index/1)
    |> Enum.reduce(pubkey, & derive_child(&2, &1))
  end

  @doc """
  TODO
  """
  @spec derive_child(t(), integer() | String.t()) :: t()
  def derive_child(%__MODULE__{} = pubkey, "M"), do: pubkey
  def derive_child(%__MODULE__{}, "m"),
    do: raise "cannot derive private child key"
  def derive_child(%__MODULE__{}, idx)
    when is_integer(idx)
    and idx >= @hardened_offset,
    do: raise "cannot derive hardened child key"
  def derive_child(%__MODULE__{key_data: k, chain_code: cc}, idx)
    when is_integer(idx)
  do
    ch = B3.hash(cc)
    z = B3.keyed_hash(<<2, k::binary, idx::little-32>>, ch, length: 64)
    c = B3.keyed_hash(<<3, k::binary, idx::little-32>>, ch, length: 64)
    <<zl::little-224, _::binary>> = z
    <<_::binary-32, cc::binary-32>> = c

    {:ok, %PubKey{point: point}} = PubKey.from_bin(k)
    key_data = Eddy.params()
    |> Map.get(:G)
    |> Eddy.Point.mul!(zl * 8)
    |> Eddy.Point.add(point)
    |> Eddy.Serializable.Encoder.serialize()

    %HDPubKey{key_data: key_data, chain_code: cc}
  end

  @doc """
  Returns the HDPubKey as a 96-byte binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{key_data: key_data, chain_code: chain_code}),
    do: key_data <> chain_code

  @doc """
  Returns the HDPubKey as a hex-encoded string.
  """
  @spec to_hex(t()) :: String.t()
  def to_hex(%__MODULE__{} = pubkey), do: to_bin(pubkey) |> bin_encode(:hex)

  @doc """
  Returns the HDPubKey as a bech32m-encoded string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = pubkey) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    to_bin(pubkey) |> b32_encode(prefix)
  end


  # TODO
  @spec to_index(String.t()) :: integer()
  defp to_index(<<m::binary-1, _::binary>>) when m in ["m", "M"], do: m
  defp to_index(part) do
    {idx, topup} = case Regex.run(~r/^(\d+)(['hH])?$/, part) do
      [^part, idx] -> {idx, 0}
      [^part, idx, _hardened] -> {idx, @hardened_offset}
    end
    case String.to_integer(idx) do
      idx when idx >= 0 and idx < @hardened_offset -> idx + topup
      _ -> raise "invalid child index: #{part}"
    end
  end
end
