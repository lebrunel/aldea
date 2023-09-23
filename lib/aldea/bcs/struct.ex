defmodule Aldea.BCS.Struct do
  @moduledoc """
  TODO
  """

  defmacro __using__(_) do
    quote do
      require Aldea.BCS.Struct
      import Aldea.BCS.Struct, only: :macros
      Module.register_attribute(__MODULE__, :bcs_fields, accumulate: true)
    end
  end

  defmacro bcs_struct(opts \\ []) do
    block = Keyword.get(opts, :do)
    quote location: :keep do
      unquote(block)

      @bcs_struct_opts @bcs_fields
        |> Enum.reverse()
        |> Enum.map(& {elem(&1, 0), Keyword.get(elem(&1, 2), :default, nil)})

      @bcs_types @bcs_fields
        |> Enum.reverse()
        |> Enum.map(& Tuple.delete_at(&1, 2))

      defstruct @bcs_struct_opts

      def bcs_read(data) when is_binary(data) do
        with {:ok, pairs, rest} <- Aldea.BCS.read(data, {:struct, @bcs_types}),
          do: {:ok, struct(__MODULE__, pairs), rest}
      end

      @spec bcs_write(binary(), struct()) :: binary()
      def bcs_write(data, %__MODULE__{} = val) when is_binary(data) do
        Aldea.BCS.write(data, val, {:struct, @bcs_types})
      end
    end
  end

  defmacro field(name, type, opts \\ []) do
    quote do: @bcs_fields {unquote(name), unquote(type), unquote(opts)}
  end

end
