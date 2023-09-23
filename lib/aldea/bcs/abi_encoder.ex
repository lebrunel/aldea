defmodule Aldea.BCS.ABIEncoder do
  #alias Aldea.{ABI, Pointer}
  alias Aldea.{ABI, Pointer}

  @doc """
  TODO
  """
  @spec decode(binary(), {ABI.t(), String.t()}) ::
    {:ok, list(any())} |
    {:error, term()}
  def decode(data, {%ABI{} = abi, subject}) when is_binary(subject) do
    cond do
      %{fields: fields} = ABI.find_class(abi, subject) ->
        decode_types(data, Enum.map(fields, & &1.type))

      %{args: args} = ABI.find_method(abi, subject) ->
        decode_types(data, Enum.map(args, & &1.type))

      true ->
        {:error, :todo}
    end
  end

  @spec decode_types(binary(), list(ABI.type_node()), list(any())) ::
    {:ok, list(any())} |
    {:error, term()}
  defp decode_types(data, types, result \\ [])
  defp decode_types(<<>>, [], result), do: {:ok, Enum.reverse(result)}
  defp decode_types(_data, [], _result), do: {:error, :todo}
  defp decode_types(data, [type | types], result) do
    with {:ok, val, rest} <- read_type(data, type) do
      decode_types(types, rest, [val | result])
    end
  end

  @doc """
  TODO
  """
  @spec read_type(binary(), BCS.type_node()) ::
    {:ok, any(), binary()} |
    {:error, term()}
  def read_type(data, %{nullable: true} = type) when is_binary(data) do
    with {:ok, bool, data} <- BCS.read(data, :bool) do
      if bool,
        do: read_type(data, Map.delete(type, :nullable)),
        else: {:ok, nil, data}
    end
  end

  def read_type(data, %{name: name})
    when is_binary(data)
    and name in ["bool", "f32", "f64", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64"],
    do: BCS.read(data, String.to_atom(name))

  def read_type(data, %{name: name})
    when is_binary(data)
    and name in [
      "ArrayBuffer", "string", "String",
      "Float32Array", "Float64Array",
      "Int8Array", "Int16Array", "Int32Array", "Int64Array",
      "Uint8Array", "Uint16Array", "Uint32Array", "Uint64Array",
    ],
    do: BCS.read_bin(data)

  def read_type(data, %{name: name, args: [t]})
    when is_binary(data)
    and name in ["Array", "StaticArray"],
    do: BCS.read_seq(data, & read_type(&1, t))

  def read_type(data, %{name: "Set", args: [t]}) when is_binary(data) do
    with {:ok, list, rest} <- BCS.read_seq(data, & read_type(&1, t)) do
      {:ok, MapSet.new(list), rest}
    end
  end

  def read_type(data, %{name: "Map", args: [k, v]}) when is_binary(data) do
    with {:ok, list, rest} <- BCS.read_seq(data, & read_key_val(&1, k, v)) do
      {:ok, Map.new(list), rest}
    end
  end

  def read_type(data, %{name: "Pointer"}) when is_binary(data) do
    with {:ok, bin, rest} <- BCS.read_bin_fixed(data, 34),
         {:ok, pointer} <- Pointer.from_bin(bin)
    do
      {:ok, pointer, rest}
    end
  end

  @doc """
  TODO
  """
  @spec write_type(binary(), BCS.type_node(), any()) :: binary()
  def write_type(data, %{nullable: true}, nil) when is_binary(data),
    do: BCS.write(data, :bool, false)
  def write_type(data, %{nullable: true} = type, val) when is_binary(data),
    do: BCS.write(data, :bool, true) |> write_type(Map.delete(type, :nullable), val)

  def write_type(data, %{name: name}, val)
    when is_binary(data)
    and name in ["bool", "f32", "f64", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64"],
    do: BCS.write(data, String.to_atom(name), val)

  def write_type(data, %{name: name}, val)
    when is_binary(data)
    and is_binary(val)
    and name in [
      "ArrayBuffer", "string", "String",
      "Float32Array", "Float64Array",
      "Int8Array", "Int16Array", "Int32Array", "Int64Array",
      "Uint8Array", "Uint16Array", "Uint32Array", "Uint64Array",
    ],
    do: BCS.write_bin(data, val)

  def write_type(data, %{name: name, args: [t]}, val)
    when is_binary(data)
    and is_list(val)
    and name in ["Array", "StaticArray"],
    do: BCS.write_seq(data, val, & write_type(&2, t, &1))

  def write_type(data, %{name: "Set", args: [t]}, %MapSet{} = set)
    when is_binary(data),
    do: BCS.write_seq(data, MapSet.to_list(set), & write_type(&2, t, &1))

  def write_type(data, %{name: "Map", args: [k, v]}, %{} = map)
    when is_binary(data)
  do
    BCS.write_seq(data, Map.to_list(map), fn {key, val}, data ->
      write_type(data, k, key) |> write_type(v, val)
    end)
  end

  def write_type(data, %{name: "Pointer"}, %Pointer{} = val)
    when is_binary(data),
    do: BCS.write_fixed_bin(data, Pointer.to_bin(val))





  @spec read_key_val(binary(), BCS.type_node(), BCS.type_node()) ::
    {:ok, BCS.elixir_type(), binary()} |
    {:error, term()}
  defp read_key_val(data, k, v) do
    with {:ok, key, data} <- read_type(data, k),
         {:ok, val, rest} <- read_type(data, v)
    do
      {:ok, {key, val}, rest}
    end
  end





end
