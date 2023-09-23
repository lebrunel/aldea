defmodule Aldea.BCS do
  @moduledoc """
  TODO
  """
  import Aldea.Encoding, only: [uleb_encode: 1, uleb_parse: 1]
  alias __MODULE__
  alias Aldea.ABI

  @type bcs_type() ::
    :bool | :f32 | :f64 |
    :i8 | :i16 | :i32 | :i64 |
    :u8 | :u16 | :u32 | :u64 |
    :uleb |
    :bin | {:bin, integer()} |
    {:list, bcs_type()} |
    {:list, integer(), bcs_type()} |
    {:map, {bcs_type(), bcs_type()}} |
    {:map, integer(), {bcs_type(), bcs_type()}} |
    {:option, bcs_type()} |
    {:tuple, list(bcs_type())} |
    {:struct, list({atom(), bcs_type()})}

  @type elixir_type() :: boolean() | float() | integer()

  @doc """
  TODO
  """
  @spec decode(binary(), bcs_type()) :: {:ok, any()} | {:error, term()}
  def decode(data, {%ABI{}, _subject} = type) when is_binary(data),
    do: BCS.ABIEncoder.decode(data, type)

  #def decode(data, :pkg) when is_binary(data),
  #  do: BCS.PkgEncoder.decode(data, type)

  def decode(data, type) when is_binary(data) do
    with {:ok, val, _rest} <- read(data, type) do
      {:ok, val}
    end
  end

  @doc """
  TODO
  """
  @spec encode(any(), bcs_type()) :: binary()
  def encode(_a, _b) do
    <<>>
  end

  @doc """
  TODO
  """
  @spec read(binary(), bcs_type()) ::
    {:ok, elixir_type(), binary()} |
    {:error, term()}
  def read(<<1, rest::binary>>, :bool), do: {:ok, true, rest}
  def read(<<0, rest::binary>>, :bool), do: {:ok, false, rest}

  def read(<<num::float-32-little, rest::binary>>, :f32), do: {:ok, num, rest}
  def read(<<num::float-64-little, rest::binary>>, :f64), do: {:ok, num, rest}

  def read(<<int::signed-8, rest::binary>>, :i8), do: {:ok, int, rest}
  def read(<<int::signed-16-little, rest::binary>>, :i16), do: {:ok, int, rest}
  def read(<<int::signed-32-little, rest::binary>>, :i32), do: {:ok, int, rest}
  def read(<<int::signed-64-little, rest::binary>>, :i64), do: {:ok, int, rest}

  def read(<<int::8, rest::binary>>, :u8), do: {:ok, int, rest}
  def read(<<int::16-little, rest::binary>>, :u16), do: {:ok, int, rest}
  def read(<<int::32-little, rest::binary>>, :u32), do: {:ok, int, rest}
  def read(<<int::64-little, rest::binary>>, :u64), do: {:ok, int, rest}

  def read(data, :uleb) when is_binary(data), do: uleb_parse(data)

  def read(data, :bin) when is_binary(data), do: read_bin(data)
  def read(data, {:bin, n}) when is_binary(data) and is_integer(n),
    do: read_bin_fixed(data, n)

  def read(data, {:list, t}) when is_binary(data),
    do: read_list(data, & read(&1, t))
  def read(data, {:list, n, t}) when is_binary(data) and is_integer(n),
    do: read_list_fixed(data, n, & read(&1, t))

  def read(data, {:map, {k, v}}) when is_binary(data) do
    with {:ok, list, rest} <- read_list(data, & read_key_val(&1, k, v)) do
      {:ok, Map.new(list), rest}
    end
  end
  def read(data, {:map, n, {k, v}}) when is_binary(data) and is_integer(n) do
    with {:ok, list, rest} <- read_list_fixed(data, n, & read_key_val(&1, k, v)) do
      {:ok, Map.new(list), rest}
    end
  end

  def read(data, {:option, t}) when is_binary(data) do
    with {:ok, bool, data} <- read(data, :bool) do
      if bool, do: read(data, t), else: {:ok, nil, data}
    end
  end

  def read(data, {:tuple, types}) when is_binary(data) and is_list(types),
    do: read_types(data, types)

  def read(data, {:struct, types}) when is_binary(data) and is_list(types),
    do: read_types_keyed(data, types)


  @doc """
  TODO
  """
  @spec read_bin(binary()) :: {:ok, binary(), binary()} | {:error, term()}
  def read_bin(data) when is_binary(data) do
    with {:ok, len, rest} <- read(data, :uleb), do: read_bin_fixed(rest, len)
  end

  @doc """
  TODO
  """
  @spec read_bin_fixed(binary(), non_neg_integer()) ::
    {:ok, binary(), binary()} |
    {:error, term()}
  def read_bin_fixed(data, len) when is_binary(data) and is_integer(len) do
    case data do
      <<data::binary-size(len), rest::binary>> -> {:ok, data, rest}
      _bin -> {:error, :invalid_length}
    end
  end

  @doc """
  TODO
  """
  @spec read_list(binary(), (binary() -> {:ok, any(), binary()})) ::
    {:ok, list(elixir_type()), binary()} |
    {:error, term()}
  def read_list(data, mapper) when is_binary(data) and is_function(mapper) do
    with {:ok, len, rest} <- read(data, :uleb),
      do: read_list_fixed(rest, len, mapper)
  end

  @doc """
  TODO
  """
  @spec read_list_fixed(binary(), non_neg_integer(), (binary() -> {:ok, any(), binary()})) ::
    {:ok, list(elixir_type()), binary()} |
    {:error, term()}
  def read_list_fixed(data, len, mapper), do: read_list_fixed(data, len, [], mapper)

  @spec read_list_fixed(
    binary(),
    non_neg_integer(),
    list(),
    (binary() -> {:ok, any(), binary()})
  ) :: {:ok, list(elixir_type()), binary()} | {:error, term()}
  defp read_list_fixed(data, 0, vals, _mapper), do: {:ok, Enum.reverse(vals), data}
  defp read_list_fixed(data, len, vals, mapper) do
    case mapper.(data) do
      {:ok, val, rest} -> read_list_fixed(rest, len-1, [val | vals], mapper)
      {:error, error} -> {:error, error}
      _ -> {:error, :todo}
    end
  end

  @doc """
  TODO
  """
  @spec read_types(binary(), list(bcs_type())) ::
    {:ok, list(any()), binary()} |
    {:error, term()}
  def read_types(data, types), do: read_types(data, types, [])

  @spec read_types(binary(), list(bcs_type()), list(any())) ::
    {:ok, list(any()), binary()} |
    {:error, term()}
  defp read_types(data, [], vals), do: {:ok, Enum.reverse(vals), data}
  defp read_types(data, [t | types], vals) do
    with {:ok, val, rest} <- read(data, t) do
      read_types(rest, types, [val | vals])
    end
  end

  @doc """
  TODO
  """
  @spec read_types(binary(), list({atom(), bcs_type()})) ::
    {:ok, map(), binary()} |
    {:error, term()}
  def read_types_keyed(data, types), do: read_types_keyed(data, types, [])

  @spec read_types_keyed(binary(), list({atom(), bcs_type()}), list(any())) ::
    {:ok, map(), binary()} |
    {:error, term()}
  defp read_types_keyed(data, [], vals), do: {:ok, Map.new(vals), data}
  defp read_types_keyed(data, [{k, t} | types], vals) do
    with {:ok, val, rest} <- read(data, t) do
      read_types_keyed(rest, types, [{k, val} | vals])
    end
  end



  @spec read_key_val(binary(), bcs_type(), bcs_type()) ::
    {:ok, elixir_type(), binary()} |
    {:error, term()}
  defp read_key_val(data, k, v) do
    with {:ok, key, data} <- read(data, k),
         {:ok, val, rest} <- read(data, v)
    do
      {:ok, {key, val}, rest}
    end
  end

  @doc """
  TODO
  """
  @spec write(binary(), bcs_type(), elixir_type()) :: binary()
  def write(data, :bool, true) when is_binary(data), do: <<data::binary, 1>>
  def write(data, :bool, false) when is_binary(data), do: <<data::binary, 0>>

  def write(data, :f32, num) when is_binary(data) and is_integer(num),
    do: <<data::binary, num::float-32-little>>

  def write(data, :f64, num) when is_binary(data) and is_integer(num),
    do: <<data::binary, num::float-64-little>>

  def write(data, :i8, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::signed-8>>

  def write(data, :i16, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::signed-16-little>>

  def write(data, :i32, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::signed-32-little>>

  def write(data, :i64, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::signed-64-little>>

  def write(data, :u8, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::8>>

  def write(data, :u16, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::16-little>>

  def write(data, :u32, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::32-little>>

  def write(data, :u64, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::64-little>>

  def write(data, :uleb, int) when is_binary(data) and is_integer(int),
    do: <<data::binary, uleb_encode(int)::binary>>

  def write(data, :bin, bin) when is_binary(data) and is_binary(bin),
    do: write_bin(data, bin)
  def write(data, {:bin, n}, bin)
    when is_binary(data) and is_integer(n)
    and is_binary(bin) and n == byte_size(bin),
    do: write_bin_fixed(data, bin)

  def write(data, {:list, t}, items) when is_binary(data) and is_list(items),
    do: write_list(data, items, & write(&2, t, &1))
  def write(data, {:list, n, t}, items)
    when is_binary(data) and is_integer(n)
    and is_list(items) and n == length(items),
    do: write_list_fixed(data, items, & write(&2, t, &1))

  def write(bin, {:option, _t}, nil), do: write(bin, :bool, false)
  def write(bin, {:option, t}, val),
    do: write(bin, :bool, true) |> write(t, val)

  @doc """
  TODO
  """
  @spec write_bin(binary(), binary()) :: binary()
  def write_bin(bin, data) when is_binary(bin) and is_binary(data),
    do: write(bin, :uleb, byte_size(data)) |> write_bin_fixed(data)

  @doc """
  TODO
  """
  @spec write_bin_fixed(binary(), binary()) :: binary()
  def write_bin_fixed(bin, data) when is_binary(bin) and is_binary(data),
    do: <<bin::binary, data::binary>>

  @doc """
  TODO
  """
  @spec write_list(binary(), list(elixir_type()), (any(), binary() -> binary())) :: binary()
  def write_list(bin, items, reducer)
    when is_binary(bin) and is_list(items) and is_function(reducer),
    do: write(bin, :uleb, length(items)) |> write_list_fixed(items, reducer)

  @doc """
  TODO
  """
  @spec write_list_fixed(binary(), list(elixir_type()), (any(), binary() -> binary())) :: binary()
  def write_list_fixed(bin, items, reducer)
    when is_binary(bin) and is_list(items) and is_function(reducer),
    do: Enum.reduce(items, reducer, bin)

end
