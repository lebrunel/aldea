defmodule Aldea.BCS.Encoder do
  @moduledoc """
  TODO
  """
  alias Aldea.BCS
  import Aldea.Encoding, only: [uleb_encode: 1]

  @type writer() :: (binary(), BCS.elixir_type() -> binary())

  @doc """
  TODO
  """
  @spec encode(BCS.elixir_type(), BCS.bcs_type()) :: binary()
  def encode(val, type), do: write(<<>>, val, type)

  @doc """
  TODO
  """
  @spec write(binary(), BCS.elixir_type(), BCS.bcs_type()) :: binary()

  # booleans
  def write(data, true, :bool) when is_binary(data), do: <<data::binary, 1>>
  def write(data, false, :bool) when is_binary(data), do: <<data::binary, 0>>

  # floats
  def write(data, num, :f32) when is_binary(data) and is_float(num),
    do: <<data::binary, num::float-32-little>>
  def write(data, num, :f64) when is_binary(data) and is_float(num),
    do: <<data::binary, num::float-64-little>>

  # signed ints
  def write(data, int, :i8) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::signed-8>>
  def write(data, int, :i16) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::signed-16-little>>
  def write(data, int, :i32) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::signed-32-little>>
  def write(data, int, :i64) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::signed-64-little>>

  # unsigned ints
  def write(data, int, :u8) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::8>>
  def write(data, int, :u16) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::16-little>>
  def write(data, int, :u32) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::32-little>>
  def write(data, int, :u64) when is_binary(data) and is_integer(int),
    do: <<data::binary, int::64-little>>

  # ulebs
  def write(data, int, :uleb) when is_binary(data) and is_integer(int),
    do: <<data::binary, uleb_encode(int)::binary>>

  # binary strings
  def write(data, bin, :bin) when is_binary(data) and is_binary(bin),
    do: <<write(data, byte_size(bin), :uleb)::binary, bin::binary>>
  def write(data, bin, {:bin, :fixed}) when is_binary(data) and is_binary(bin),
    do: write(data, bin, {:bin, byte_size(bin)})
  def write(data, bin, {:bin, n})
    when is_binary(data) and is_binary(bin)
    and is_integer(n) and n == byte_size(bin),
    do: <<data::binary, bin::binary>>

  # sequences
  def write(data, list, {:seq, t}) when is_binary(data) and is_list(list),
    do: write_seq(data, list, & write(&1, &2, t))
  def write(data, list, {:seq, n, t})
    when is_binary(data) and is_list(list)
    and is_integer(n) and n == length(list),
    do: write_seq_fixed(data, list, & write(&1, &2, t))

  # maps
  def write(data, pairs, {:map, t}) when is_binary(data) and is_map(pairs),
    do: write(data, Enum.into(pairs, []), {:map, t})
  def write(data, pairs, {:map, t}) when is_binary(data) and is_list(pairs),
    do: write_seq(data, pairs, & map_writer(&1, &2, t))
  def write(data, pairs, {:map, n, t})
    when is_binary(data) and is_map(pairs),
    do: write(data, Enum.into(pairs, []), {:map, n, t})
  def write(data, pairs, {:map, n, t})
    when is_binary(data) and is_list(pairs)
    and is_integer(n) and n == length(pairs),
    do: write_seq_fixed(data, pairs, & map_writer(&1, &2, t))

  # options
  def write(data, nil, {:option, _t}), do: write(data, false, :bool)
  def write(data, val, {:option, t}),
    do: write(data, true, :bool) |> write(val, t)

  # tuples
  def write(data, vals, {:tuple, types})
    when is_binary(data) and is_list(types) and is_tuple(vals),
    do: write_each(data, Tuple.to_list(vals), types)
  def write(data, vals, {:tuple, types})
    when is_binary(data) and is_list(types) and is_list(vals),
    do: write_each(data, vals, types)

  # struct
  def write(data, val, {:struct, pairs})
    when is_binary(data) and is_list(pairs) and is_map(val),
    do: write_each(data, Enum.map(pairs, fn {k, _v} -> Map.get(val, k) end), Keyword.values(pairs))
  def write(data, vals, {:struct, pairs})
    when is_binary(data) and is_list(pairs) and is_list(vals),
    do: write_each(data, Keyword.values(vals), Keyword.values(pairs))

  # modules
  def write(data, val, {:mod, mod}) when is_binary(data) and is_atom(mod),
    do: apply(mod, :bcs_write, [data, val])

  @doc """
  TODO
  """
  @spec write_each(binary(), list(BCS.elixir_type()), list(BCS.bcs_type())) :: binary()
  def write_each(data, [], []) when is_binary(data), do: data
  def write_each(data, [val | vals], [t | types])
    when is_binary(data) and length(vals) == length(types),
    do: write(data, val, t) |> write_each(vals, types)

  @doc """
  TODO
  """
  @spec write_seq(
    binary(),
    list(BCS.elixir_type()),
    writer()
  ) :: binary()
  def write_seq(data, items, writer)
    when is_binary(data)
    and is_list(items)
    and is_function(writer),
    do: write(data, length(items), :uleb) |> write_seq_fixed(items, writer)

  @doc """
  TODO
  """
  @spec write_seq_fixed(
    binary(),
    list(BCS.elixir_type()),
    writer()
  ) :: binary()
  def write_seq_fixed(data, items, writer)
    when is_binary(data)
    and is_list(items)
    and is_function(writer),
    do: Enum.reduce(items, data, & writer.(&2, &1))


  # todo
  @spec map_writer(
    binary(),
    {BCS.elixir_type(), BCS.elixir_type()},
    {BCS.bcs_type(), BCS.bcs_type()}
  ) :: binary()
  defp map_writer(data, {key, val}, {k, v}) do
    data
    |> write(key, k)
    |> write(val, v)
  end
end
