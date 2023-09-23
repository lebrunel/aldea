defmodule Aldea.HDPrivKey do
  @moduledoc """
  TODO
  """
  alias Aldea.{
    HDPubKey
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
    key_data: <<_::512>>,
    chain_code: <<_::256>>,
  }

  @n_2_pow_256 2 ** 256
  @bech32_prefix %{
    main: "xsec",
    test: "xsec_test"
  }
  @hardened_offset 0x80000000
  @master_secret "ed25519 seed"

  @doc """
  Securely generates a new random HD PrivKey.
  """
  @spec generate_key() :: t()
  def generate_key(), do: from_seed(:crypto.strong_rand_bytes(64))

  @doc """
  Returns a HDPrivKey from the given 96-byte binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) when is_binary(bin) do
    case bin do
      <<kd::binary-64, cc::binary-32>> ->
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
  @spec from_seed(binary()) :: t()
  def from_seed(seed)
    when is_binary(seed)
    and bit_size(seed) in [128, 256, 512]
  do
    key = B3.derive_key(seed, @master_secret)
    derive_root_key(seed, key)
  end

  @doc """
  TODO
  """
  @spec get_pubkey_bytes(t()) :: binary()
  def get_pubkey_bytes(%__MODULE__{key_data: <<k::little-256, _::binary-32>>}) do
    Eddy.params()
    |> Map.get(:G)
    |> Eddy.Point.mul!(k)
    |> Eddy.Serializable.Encoder.serialize()
  end

  @doc """
  TODO
  """
  @spec derive(t(), String.t()) :: t()
  def derive(%__MODULE__{} = privkey, path) when is_binary(path) do
    unless String.match?(path, ~r/^[mM]['hH]?(\/\d+['hH]?)+/) do
      raise "invalid derivation path"
    end

    path
    |> String.split("/")
    |> Enum.map(&to_index/1)
    |> Enum.reduce(privkey, & derive_child(&2, &1))
  end

  @doc """
  TODO
  """
  @spec derive_child(t(), integer() | String.t()) :: t()
  def derive_child(%__MODULE__{} = privkey, "m"), do: privkey
  def derive_child(%__MODULE__{} = privkey, "M"), do: HDPubKey.from_hd_privkey(privkey)
  def derive_child(
    %__MODULE__{key_data: <<kl::little-256, kr::little-256>> = k, chain_code: cc} = privkey,
    idx
  ) when is_integer(idx) do
    ch = B3.hash(cc)
    pk = get_pubkey_bytes(privkey)

    {z, c} = if idx < @hardened_offset do
      z = B3.keyed_hash(<<2, pk::binary, idx::little-32>>, ch, length: 64)
      c = B3.keyed_hash(<<3, pk::binary, idx::little-32>>, ch, length: 64)
      {z, c}
    else
      z = B3.keyed_hash(<<0, k::binary, idx::little-32>>, ch, length: 64)
      c = B3.keyed_hash(<<1, k::binary, idx::little-32>>, ch, length: 64)
      {z, c}
    end

    <<zl::little-224, _::binary-4, zr::little-256>> = z
    <<_::binary-32, cc::binary-32>> = c

    left = (zl * 8) + kl
    right = Eddy.Util.mod(zr + kr, @n_2_pow_256)

    struct(__MODULE__, [
      key_data: <<left::little-256, right::little-256>>,
      chain_code: cc
    ])
  end

  @doc """
  Returns the HDPrivKey as a 96-byte binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{key_data: k, chain_code: c}), do: k <> c

  @doc """
  Returns the HDPrivKey as a hex-encoded string.
  """
  @spec to_hex(t()) :: String.t()
  def to_hex(%__MODULE__{} = privkey), do: to_bin(privkey) |> bin_encode(:hex)

  @doc """
  Returns the HDPrivKey as a bech32m-encoded string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = privkey) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    to_bin(privkey) |> b32_encode(prefix)
  end

  # TODO
  @spec derive_root_key(binary(), binary()) :: t()
  defp derive_root_key(block, key) do
    <<prefix::binary-32, chain_data::binary>> = block = B3.keyed_hash(block, key, length: 64)
    <<e0, ea::binary-30, e31, eb::binary>> = B3.hash(prefix, length: 64)

    if Bitwise.band(e31, 0x20) == 0 do
      e0 = Bitwise.band(e0, Bitwise.bnot(0x07))
      e31 = Bitwise.band(e31, Bitwise.bnot(0x80))
      e31 = Bitwise.bor(e31, 0x40)
      struct(__MODULE__, [
        key_data: <<e0, ea::binary, e31, eb::binary>>,
        chain_code: chain_data,
      ])
    else
      derive_root_key(block, key)
    end
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
