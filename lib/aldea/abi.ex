defmodule Aldea.ABI do
  @moduledoc """
  TODO
  """
  alias Aldea.BCS

  @derive Jason.Encoder
  defstruct version: 1,
            exports: [],
            imports: [],
            objects: [],
            types_ids: []

  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    exports: list(export_node()),
    imports: list(import_node()),
    objects: list(object_node()),
    types_ids: list(type_id_node()),
  }

  @type kind_enum() :: non_neg_integer()

  @type export_node() :: %{
    kind: kind_enum(),
    code: class_node() | function_node() | interface_node(),
  }

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
  @spec find_export(t(), String.t()) :: export_node() | nil
  def find_export(%__MODULE__{} = abi, name) when is_binary(name) do
    Enum.find(abi.exports, & &1.code.name == name)
  end

  @spec find_export(t(), String.t(), kind_enum()) :: export_node() | nil
  def find_export(%__MODULE__{} = abi, name, kind) when is_binary(name) and is_atom(kind) do
    Enum.find(abi.exports, & &1.code.name == name and &1.kind === @code_kind[kind])
  end

  @doc """
  TODO
  """
  @spec find_class(t(), String.t()) :: class_node() | nil
  def find_class(%__MODULE__{} = abi, name) when is_binary(name) do
    with %{code: code} <- find_export(abi, name, :class), do: code
  end

  @doc """
  TODO
  """
  @spec find_interface(t(), String.t()) :: interface_node() | nil
  def find_interface(%__MODULE__{} = abi, name) when is_binary(name) do
    with %{code: code} <- find_export(abi, name, :interface), do: code
  end

  @doc """
  TODO
  """
  @spec find_function(t(), String.t()) :: function_node() | nil
  def find_function(%__MODULE__{} = abi, name) when is_binary(name) do
    with %{code: code} <- find_export(abi, name, :function), do: code
  end

  @doc """
  TODO
  """
  @spec find_method(t(), String.t()) :: method_node() | nil
  def find_method(%__MODULE__{} = abi, name) when is_binary(name) do
    with [class_name, fn_name] <- String.split(name, ~r/(_|\$)/),
         %{methods: methods} <- find_class(abi, class_name)
    do
      Enum.find(methods, & &1.name === fn_name)
    else
      _ -> nil
    end
  end

  @doc """
  TODO
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(data) when is_binary(data) do
    with {:ok, abi} <- BCS.decode(:abi, data) do
      {:ok, struct(__MODULE__, abi)}
    end
  end

  @doc """
  TODO
  """
  @spec from_json(String.t()) :: {:ok, t()} | {:error, term()}
  def from_json(data) when is_binary(data) do
    with {:ok, abi} <- Jason.decode(:abi, data) do
      {:ok, struct(__MODULE__, abi)}
    end
  end

  @doc """
  TODO
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{} = abi) do
    BCS.encode(:abi, abi)
  end

  @doc """
  TODO
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = abi) do
    Jason.encode(abi)
  end

  defimpl BCS.Encodable do
    @impl true
    def read(abi, data) do
      with {:ok, version, data} <- BCS.read(data, :u16),
           {:ok, exports, data} <- BCS.read_seq(data, &read_export_node/1),
           {:ok, imports, data} <- BCS.read_seq(data, &read_import_node/1),
           {:ok, objects, data} <- BCS.read_seq(data, &read_object_node/1),
           {:ok, type_ids, rest} <- BCS.read_seq(data, &read_type_id_node/1)
      do
        {:ok, struct(abi, [
          version: version,
          exports: exports,
          imports: imports,
          objects: objects,
          type_ids: type_ids,
        ]), rest}
      end
    end

    @spec read_export_node(binary()) ::
      {:ok, ABI.export_node(), binary()} |
      {:error, term()}
    defp read_export_node(data) do
      with {:ok, kind, data} <- BCS.read(data, :u8),
           {:ok, code, rest} <- read_code_node(kind, data)
      do
        {:ok, %{
          kind: kind,
          code: code,
        }, rest}
      end
    end

    @spec read_code_node(ABI.kind_enum(), binary()) ::
      {:ok, ABI.class_node() | ABI.function_node() | ABI.interface_node(), binary()} |
      {:error, term()}
    defp read_code_node(0, data), do: read_class_node(data)
    defp read_code_node(1, data), do: read_function_node(data)
    defp read_code_node(2, data), do: read_interface_node(data)

    @spec read_class_node(binary()) ::
      {:ok, ABI.class_node(), binary()} |
      {:error, term()}
    defp read_class_node(data) do
      with {:ok, name, data} <- BCS.read_bin(data),
           {:ok, extends, data} <- BCS.read_bin(data),
           {:ok, implements, data} <- BCS.read_seq(data, &BCS.read_bin/1),
           {:ok, fields, data} <- BCS.read_seq(data, &read_field_node/1),
           {:ok, methods, rest} <- BCS.read_seq(data, &read_method_node/1)
      do
        {:ok, %{
          name: name,
          extends: extends,
          implements: implements,
          fields: fields,
          methods: methods,
        }, rest}
      end
    end

    @spec read_function_node(binary()) ::
      {:ok, ABI.function_node(), binary()} |
      {:error, term()}
    defp read_function_node(data) do
      with {:ok, name, data} <- BCS.read_bin(data),
           {:ok, args, data} <- BCS.read_seq(data, &read_arg_node/1),
           {:ok, rtype, rest} <- read_type_node(data)
      do
        {:ok, %{
          name: name,
          args: args,
          rtype: rtype,
        }, rest}
      end
    end

    @spec read_interface_node(binary()) ::
      {:ok, ABI.interface_node(), binary()} |
      {:error, term()}
    defp read_interface_node(data) do
      with {:ok, name, data} <- BCS.read_bin(data),
           {:ok, extends, data} <- BCS.read_bin(data),
           {:ok, implements, data} <- BCS.read_seq(data, &BCS.read_bin/1),
           {:ok, fields, data} <- BCS.read_seq(data, &read_field_node/1),
           {:ok, methods, rest} <- BCS.read_seq(data, &read_method_node/1)
      do
        {:ok, %{
          name: name,
          extends: extends,
          implements: implements,
          fields: fields,
          methods: methods,
        }, rest}
      end
    end

    @spec read_import_node(binary()) ::
      {:ok, ABI.import_node(), binary()} |
      {:error, term()}
    defp read_import_node(data) do
      with {:ok, kind, data} <- BCS.read(data, :u8),
           {:ok, name, data} <- BCS.read_bin(data),
           {:ok, pkg, rest} <- BCS.read_bin(data)
      do
        {:ok, %{
          kind: kind,
          name: name,
          pkg: pkg,
        }, rest}
      end
    end

    @spec read_object_node(binary()) ::
      {:ok, ABI.object_node(), binary()} |
      {:error, term()}
    defp read_object_node(data) do
      with {:ok, name, data} <- BCS.read_bin(data),
           {:ok, fields, rest} <- BCS.read_seq(data, &read_field_node/1)
      do
        {:ok, %{
          name: name,
          fields: fields,
        }, rest}
      end
    end

    @spec read_field_node(binary()) ::
      {:ok, ABI.field_node(), binary()} |
      {:error, term()}
    defp read_field_node(data) do
      with {:ok, kind, data} <- BCS.read(data, :u8),
           {:ok, name, data} <- BCS.read_bin(data),
           {:ok, type, rest} <- read_type_node(data)
      do
        {:ok, %{
          kind: kind,
          name: name,
          type: type,
        }, rest}
      end
    end

    @spec read_method_node(binary()) ::
      {:ok, ABI.method_node(), binary()} |
      {:error, term()}
    defp read_method_node(data) do
      with {:ok, kind, data} <- BCS.read(data, :u8),
           {:ok, name, data} <- BCS.read_bin(data),
           {:ok, args, data} <- BCS.read_seq(data, &read_arg_node/1),
           {:ok, rtype, rest} <- read_type_node(data)
      do
        {:ok, %{
          kind: kind,
          name: name,
          args: args,
          rtype: rtype,
        }, rest}
      end
    end

    @spec read_arg_node(binary()) ::
      {:ok, ABI.arg_node(), binary()} |
      {:error, term()}
    defp read_arg_node(data) do
      with {:ok, name, data} <- BCS.read_bin(data),
           {:ok, type, rest} <- read_type_node(data)
      do
        {:ok, %{
          name: name,
          type: type,
        }, rest}
      end
    end

    @spec read_type_node(binary()) ::
      {:ok, ABI.type_node(), binary()} |
      {:error, term()}
    defp read_type_node(data) do
      with {:ok, name, data} <- BCS.read_bin(data),
           {:ok, nullable, data} <- BCS.read(data, :bool),
           {:ok, args, rest} <- BCS.read_seq(data, &read_type_node/1)
      do
        {:ok, %{
          name: name,
          nullable: nullable,
          args: args,
        }, rest}
      end
    end

    @spec read_type_id_node(binary()) ::
      {:ok, ABI.type_id_node(), binary()} |
      {:error, term()}
    defp read_type_id_node(data) do
      with {:ok, id, data} <- BCS.read(data, :u32),
           {:ok, name, rest} <- BCS.read_bin(data)
      do
        {:ok, %{
          id: id,
          name: name,
        }, rest}
      end
    end

  end

end
