defmodule Aldea.PrivKey do
  @moduledoc """
  An Aldea Private Key is random 32-byte binary.
  """
  import Eddy.Util, only: [decode: 2, encode: 2]

  defstruct [:d]

  @typedoc "Private Key"
  @type t() :: %__MODULE__{d: <<_::256>>}

  @bech32_prefix %{
    main: "asec",
    test: "asec_test"
  }

  @doc """
  Securely generates a new random PrivKey.
  """
  @spec generate_key() :: t()
  def generate_key() do
    d = Eddy.generate_key(encoding: :bin)
    struct(__MODULE__, d: d)
  end

  @doc """
  Returns a PrivKey from the given 32-byte binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) when is_binary(bin) do
    case byte_size(bin) do
      32 -> {:ok, struct(__MODULE__, d: bin)}
      n -> {:error, {:invalid_length, n}}
    end
  end

  @doc """
  Returns a PrivKey from the given hex-encoded string.
  """
  @spec from_hex(String.t()) :: {:ok, t()} | {:error, term()}
  def from_hex(hex) when is_binary(hex) do
    with {:ok, bin} <- decode(hex, :hex) do
      from_bin(bin)
    end
  end

  @doc """
  Returns a PrivKey from the given bech32m-encoded string.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, term()}
  def from_string(str) when is_binary(str) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    with {:ok, {^prefix, bin, :bech32m}} <- ExBech32.decode(str) do
      from_bin(bin)
    end
  end

  @doc """
  Returns the PrivKey as a 32-byte binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{d: d}), do: d

  @doc """
  Returns the PrivKey as a hex-encoded string.
  """
  @spec to_hex(t()) :: String.t()
  def to_hex(%__MODULE__{d: d}), do: encode(d, :hex)

  @doc """
  Returns the PrivKey as a bech32m-encoded string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{d: d}) do
    prefix = Map.get(@bech32_prefix, Aldea.network())
    with {:ok, str} <- ExBech32.encode(prefix, d, :bech32m) do
      str
    end
  end

end
