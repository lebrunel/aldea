defmodule Aldea.BCS.Decoder do
  @moduledoc """
  An decoder module for Aldea Binary Coding Standard (BCS). It provides
  functions to decode data into different types.
  """
  alias Aldea.BCS
  import Aldea.Encoding, only: [uleb_parse: 1]

  @doc """
  Decodes a given binary data into the specified type.
  """
  @spec decode(binary(), BCS.bcs_type()) ::
    {:ok, BCS.elixir_type()} |
    {:error, term()}
  def decode(data, type) when is_binary(data) do
    with {:ok, val, _rest} <- read(data, type), do: {:ok, val}
  end

  @doc """
  Reads a binary data and returns the result based on the specified type.
  """
  @spec read(binary(), BCS.bcs_type()) :: BCS.read_result()

  # booleans
  def read(<<1, rest::binary>>, :bool), do: {:ok, true, rest}
  def read(<<0, rest::binary>>, :bool), do: {:ok, false, rest}

  # floats
  def read(<<num::float-32-little, rest::binary>>, :f32), do: {:ok, num, rest}
  def read(<<num::float-64-little, rest::binary>>, :f64), do: {:ok, num, rest}

  # signed ints
  def read(<<int::signed-8, rest::binary>>, :i8), do: {:ok, int, rest}
  def read(<<int::signed-16-little, rest::binary>>, :i16), do: {:ok, int, rest}
  def read(<<int::signed-32-little, rest::binary>>, :i32), do: {:ok, int, rest}
  def read(<<int::signed-64-little, rest::binary>>, :i64), do: {:ok, int, rest}

  # unsigned ints
  def read(<<int::8, rest::binary>>, :u8), do: {:ok, int, rest}
  def read(<<int::16-little, rest::binary>>, :u16), do: {:ok, int, rest}
  def read(<<int::32-little, rest::binary>>, :u32), do: {:ok, int, rest}
  def read(<<int::64-little, rest::binary>>, :u64), do: {:ok, int, rest}

  # ulebs
  def read(data, :uleb) when is_binary(data), do: uleb_parse(data)

  # binary strings
  def read(data, :bin) when is_binary(data) do
    with {:ok, n, rest} <- read(data, :uleb), do: read(rest, {:bin, n})
  end
  def read(data, {:bin, :fixed}) when is_binary(data),
    do: read(data, {:bin, byte_size(data)})
  def read(data, {:bin, n}) when is_binary(data) and is_integer(n) do
    case data do
      <<data::binary-size(n), rest::binary>> -> {:ok, data, rest}
      _bin -> {:error, :bin_read}
    end
  end

  # sequences
  def read(data, {:seq, t}) when is_binary(data),
    do: read_seq(data, & read(&1, t))

  def read(data, {:seq, n, t}) when is_binary(data) and is_integer(n),
    do: read_seq_fixed(data, n, & read(&1, t))

  # maps
  def read(data, {:map, {k, v}}) when is_binary(data) do
    with {:ok, val, rest} <- read_seq(data, & map_reader(&1, k, v)),
      do: {:ok, Enum.into(val, %{}), rest}
  end
  def read(data, {:map, n, {k, v}}) when is_binary(data) and is_integer(n) do
    with {:ok, val, rest} <- read_seq_fixed(data, n, & map_reader(&1, k, v)),
      do: {:ok, Enum.into(val, %{}), rest}
  end

  # options
  def read(data, {:option, t}) when is_binary(data) do
    with {:ok, bool, data} <- read(data, :bool) do
      if bool, do: read(data, t), else: {:ok, nil, data}
    end
  end

  # tuples
  def read(data, {:tuple, types}) when is_binary(data) and is_list(types) do
    read_each(data, types)
  end

  # struct
  def read(data, {:struct, pairs}) when is_binary(data) and is_list(pairs) do
    with {:ok, vals, rest} <- read_each(data, Keyword.values(pairs)) do
      val = List.zip([Keyword.keys(pairs), vals]) |> Enum.into(%{})
      {:ok, val, rest}
    end
  end

  # modules
  def read(data, {:mod, mod}) when is_binary(data) and is_atom(mod),
    do: apply(mod, :bcs_read, [data])

  def read(_data, _type), do: {:error, :bcs_read}

  @doc """
  Reads each type from the binary data.
  """
  @spec read_each(binary(), list(BCS.bcs_type())) :: BCS.read_result()
  def read_each(data, types) when is_binary(data) and is_list(types),
    do: read_each(data, types, [])

  @spec read_each(
    binary(),
    list(BCS.bcs_type()),
    list(BCS.elixir_type())
  ) :: BCS.read_result()
  defp read_each(data, [], vals), do: {:ok, Enum.reverse(vals), data}
  defp read_each(data, [type | types], vals) do
    with {:ok, val, rest} <- read(data, type),
      do: read_each(rest, types, [val | vals])
  end

  @doc """
  Reads a sequence from the binary data.
  """
  @spec read_seq(
    binary(),
    (binary() -> BCS.read_result())
  ) :: BCS.read_result()
  def read_seq(data, reader) when is_binary(data) and is_function(reader) do
    with {:ok, n, rest} <- read(data, :uleb), do: read_seq_fixed(rest, n, reader)
  end

  @doc """
  Reads a fixed-size sequence from the binary data.
  """
  @spec read_seq_fixed(
    binary(),
    non_neg_integer(),
    (binary() -> BCS.read_result())
  ) :: BCS.read_result()
  def read_seq_fixed(data, n, reader)
    when is_binary(data) and is_integer(n) and is_function(reader),
    do: read_seq_fixed(data, n, [], reader)

  @spec read_seq_fixed(
    binary(),
    non_neg_integer(),
    list(BCS.elixir_type()),
    (binary() -> BCS.read_result())
  ) :: BCS.read_result()
  defp read_seq_fixed(data, 0, vals, _reader), do: {:ok, Enum.reverse(vals), data}
  defp read_seq_fixed(data, len, vals, reader) do
    with {:ok, val, rest} <- reader.(data),
      do: read_seq_fixed(rest, len-1, [val | vals], reader)
  end

  # Helper function for reading maps.
  @spec map_reader(binary(), BCS.bcs_type(), BCS.bcs_type()) :: BCS.read_result()
  defp map_reader(data, k, v) do
    with {:ok, key, data} <- read(data, k),
         {:ok, val, rest} <- read(data, v)
    do
      {:ok, {key, val}, rest}
    end
  end
end
