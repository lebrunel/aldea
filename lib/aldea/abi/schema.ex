defmodule Aldea.ABI.Schema do
  @moduledoc false
  alias Aldea.ABI

  def init, do: [
    version: :u16,
    imports: {:seq, :u16 },
    exports: {:seq, :u16 },
    defs: {:seq, {:mod, __MODULE__.CodeDefNode }},
    type_ids: {:seq, type_id_node() },
  ]

  def proxy_node, do: {:struct, [
    kind: :u8,
    name: :bin,
    pkg: :bin
  ]}

  def class_node, do: {:struct, [
    name: :bin,
    extends: :bin,
    implements: {:seq, :bin},
    fields: {:seq, field_node()},
    methods: {:seq, method_node()},
  ]}

  def field_node, do: {:struct, [
    name: :bin,
    type: {:mod, __MODULE__.TypeNode},
  ]}

  def method_node, do: {:struct, [
    kind: :u8,
    name: :bin,
    args: {:seq, arg_node()},
    rtype: {:option, {:mod, __MODULE__.TypeNode}},
  ]}

  def arg_node, do: {:struct, [
    name: :bin,
    type: {:mod, __MODULE__.TypeNode},
  ]}

  def function_node, do: {:struct, [
    name: :bin,
    args: {:seq, arg_node()},
    rtype: {:mod, __MODULE__.TypeNode},
  ]}

  def interface_node, do: {:struct, [
    name: :bin,
    extends: {:seq, :bin},
    fields: {:seq, field_node()},
    methods: {:seq, method_node()},
  ]}

  def object_node, do: {:struct, [
    name: :bin,
    fields: {:seq, field_node()},
  ]}

  def type_id_node, do: {:struct, [
    id: :u32,
    name: :bin,
  ]}

  defmodule CodeDefNode do
    @moduledoc false
    alias Aldea.{ABI, BCS}
    @behaviour BCS.Encodable

    def bcs_read(data) when is_binary(data) do
      with {:ok, kind, data} <- BCS.read(data, :u8),
           {:ok, code, data} <- BCS.read(data, code_schema(kind))
      do
        {:ok, Map.put(code, :kind, kind), data}
      end
    end

    def bcs_write(data, %{kind: kind} = code) when is_binary(data) do
      data
      |> BCS.write(kind, :u8)
      |> BCS.write(code, code_schema(kind))
    end

    defp code_schema(0), do: ABI.Schema.class_node()
    defp code_schema(1), do: ABI.Schema.function_node()
    defp code_schema(2), do: ABI.Schema.interface_node()
    defp code_schema(3), do: ABI.Schema.object_node()
    defp code_schema(n) when n in 100..102, do: ABI.Schema.proxy_node()
  end


  defmodule TypeNode do
    @moduledoc false
    require Aldea.BCS
    alias Aldea.BCS

    BCS.defschema name: :bin,
                  nullable: :bool,
                  args: {:seq, {:mod, __MODULE__}}

  end
end
