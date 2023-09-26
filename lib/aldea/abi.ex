defmodule Aldea.ABI do
  @moduledoc """
  TODO
  """
  alias Aldea.{BCS, Pointer}

  @derive Jason.Encoder

  defstruct version: 1,
            exports: [],
            imports: [],
            objects: [],
            type_ids: []

  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    exports: list(export_node()),
    imports: list(import_node()),
    objects: list(object_node()),
    type_ids: list(type_id_node()),
  }

  @type kind_enum() :: non_neg_integer()

  @type export_node() :: %{
    kind: kind_enum(),
    code: code_node(),
  }

  @type code_node() :: class_node() | function_node() | interface_node()

  @type class_node() :: %{
    name: String.t(),
    extends: String.t(),
    implements: list(String.t()),
    fields: list(field_node()),
    methods: list(method_node()),
  }

  @type function_node() :: %{
    name: String.t(),
    args: list(arg_node()),
    rtype: type_node(),
  }

  @type interface_node() :: %{
    name: String.t(),
    extends: String.t() | nil,
    fields: list(field_node()),
    methods: list(method_node()),
  }

  @type import_node() :: %{
    kind: kind_enum(),
    name: String.t(),
    pkg: String.t(),
  }

  @type object_node() :: %{
    name: String.t(),
    fields: list(field_node()),
  }

  @type field_node() :: %{
    kind: kind_enum(),
    name: String.t(),
    type: type_node(),
  }

  @type method_node() :: %{
    kind: kind_enum(),
    name: String.t(),
    args: list(arg_node()),
    rtype: type_node() | nil,
  }

  @type arg_node() :: %{
    name: String.t(),
    type: type_node(),
  }

  @type type_node() :: %{
    name: String.t(),
    nullable: boolean(),
    args: list(type_node()),
  }

  @type type_id_node() :: %{
    id: non_neg_integer(),
    name: String.t(),
  }

  @code_kind %{
    class: 0,
    function: 1,
    interface: 2,
  }

  @field_kind %{
    public: 0,
    private: 1,
    protected: 2,
  }

  @method_kind %{
    static: 0,
    constructor: 1,
    public: 2,
    private: 3,
    protected: 4,
  }

  @doc """
  TODO
  """
  @spec bcs_decode(t(), String.t(), binary()) ::
    {:ok, list(BCS.elixir_type())} | {:error, term()}
  def bcs_decode(%__MODULE__{} = abi, key, data)
    when is_binary(key) and is_binary(data)
  do
    case find_node(abi, key) do
      # Is a method or function
      %{args: args} ->
        with {:ok, indexes, data} <- BCS.read(data, {:seq, :u8}) do
          types = Enum.reduce(indexes, Enum.map(args, & to_bcs_type(&1.type)), fn i, args ->
            List.replace_at(args, i, :u16)
          end)

          with {:ok, vals, _rest} <- BCS.read(data, {:tuple, types}) do
            {:ok, Enum.reduce(indexes, vals, fn i, vals ->
              List.update_at(vals, i, & {:ref, &1})
            end)}
          end
        end

      # Is a class
      %{fields: fields, implements: _} ->
        types = Enum.map(fields, & to_bcs_type(&1.type))
        BCS.decode(data, {:tuple, types})

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  TODO
  """
  @spec bcs_encode(t(), String.t(), list(BCS.elixir_type())) :: binary()
  def bcs_encode(%__MODULE__{} = abi, key, vals)
    when is_binary(key) and is_list(vals)
  do
    case find_node(abi, key) do
      # Is a method or function
      %{args: args} ->
        indexes =
          vals
          |> Enum.with_index()
          |> Enum.filter(& match?({:ref, _n}, elem(&1, 0)))
          |> Enum.map(& elem(&1, 1))

        vals = Enum.reduce(indexes, vals, fn i, vals ->
          List.update_at(vals, i, & elem(&1, 1))
        end)

        types = Enum.reduce(indexes, Enum.map(args, & to_bcs_type(&1.type)), fn i, args ->
          List.replace_at(args, i, :u16)
        end)

        indexes
        |> BCS.encode({:seq, :u8})
        |> BCS.write(vals, {:tuple, types})

      # Is a class
      %{fields: fields, implements: _} ->
        types = Enum.map(fields, & to_bcs_type(&1.type))
        BCS.encode(vals, {:tuple, types})

      nil ->
        raise "ABI error: #{key} not found"
    end
  end

  @doc """
  TODO
  """
  @spec find_code(t(), String.t()) :: code_node() | nil
  def find_code(%__MODULE__{exports: exports}, name) when is_binary(name) do
    with %{code: code} <- Enum.find(exports, & &1.code.name === name), do: code
  end

  @spec find_code(t(), String.t(), atom()) :: code_node() | nil
  def find_code(%__MODULE__{exports: exports}, name, kind)
    when is_binary(name) and is_atom(kind)
  do
    with %{code: code} <- Enum.find(exports, & &1.code.name === name and &1.kind === @code_kind[kind]), do: code
  end

  @doc """
  TODO
  """
  @spec from_json(String.t()) :: {:ok, t()} | {:error, term()}
  def from_json(data) when is_binary(data) do
    with {:ok, abi} <- Jason.decode(data) do
      {:ok, struct(__MODULE__, Recase.Enumerable.convert_keys(abi, fn key ->
        key
        |> Recase.to_snake()
        |> Recase.Generic.safe_atom()
      end))}
    end
  end

  @doc """
  TODO
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = abi) do
    abi
    |> Map.from_struct()
    |> Recase.Enumerable.convert_keys(&Recase.to_camel/1)
    |> Jason.encode!(pretty: true)
  end

  # TODO
  @spec find_node(t(), String.t()) :: code_node() | method_node() | nil
  defp find_node(%__MODULE__{} = abi, key) when is_binary(key) do
    case Regex.run(~r/^(\w+)(\$|_)(\w+)$/, key) do
      [^key, class_name | tail] ->
        with %{methods: methods} <- find_code(abi, class_name, :class) do
          case tail do
            [_, "constructor"] ->
              Enum.find(methods, & &1.name == "constructor" and &1.kind == @method_kind[:constructor])
            ["_", method_name] ->
              Enum.find(methods, & &1.name == method_name and &1.kind == @method_kind[:static])
            ["$", method_name] ->
              Enum.find(methods, & &1.name == method_name and &1.kind == @method_kind[:public])
          end
        end
      nil ->
        find_code(abi, key)
    end
  end

  # TODO
  @spec to_bcs_type(type_node()) :: BCS.bcs_type()
  defp to_bcs_type(%{nullable: true} = type),
    do: {:option, to_bcs_type(Map.put(type, :nullable, false))}

  defp to_bcs_type(%{name: name}) when name in [
    "bool",
    "f32", "f64",
    "i8", "i16", "i32", "i64",
    "u8", "u16", "u32", "u64",
  ], do: String.to_atom(name)

  defp to_bcs_type(%{name: name}) when name in [
    "string", "String",
    "ArrayBuffer",
    "Float32Array", "Float64Array",
    "Int8Array", "Int16Array", "Int32Array", "Int64Array",
    "Uint8Array", "Uint16Array", "Uint32Array", "Uint64Array",
  ], do: :bin

  defp to_bcs_type(%{name: name, args: [t]}) when name in [
    "Array", "StaticArray", "Set",
  ], do: {:seq, to_bcs_type(t)}

  defp to_bcs_type(%{name: "Map", args: [k, v]}),
    do: {:map, {to_bcs_type(k), to_bcs_type(v)}}

  defp to_bcs_type(%{name: "Pointer"}), do: {:mod, Pointer}

end
