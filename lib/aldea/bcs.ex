defmodule Aldea.BCS do
  @moduledoc """
  This module provides a Binary Canonical Serialization (BCS) system for Elixir.
  It includes types and functions for encoding and decoding data.
  """
  alias Aldea.BCS.{Decoder, Encoder}

  @typedoc """
  BCS type that describes the possible types of data that can be serialized
  """
  @type bcs_type() ::
    :bool |
    :f32 | :f64 |
    :i8 | :i16 | :i32 | :i64 |
    :u8 | :u16 | :u32 | :u64 |
    :uleb |
    :bin | {:bin, non_neg_integer()} |
    {:seq, bcs_type()} | {:seq, non_neg_integer(), bcs_type()} |
    {:map, {bcs_type(), bcs_type()}} | {:map, non_neg_integer(), {bcs_type(), bcs_type()}} |
    {:option, bcs_type()} |
    {:tuple, list(bcs_type())} |
    {:struct, list({atom(), bcs_type()})}

  @typedoc """
  Elixir types that can be serialized
  """
  @type elixir_type() ::
    boolean() |
    float() |
    integer() |
    binary() |
    list(elixir_type()) |
    list({atom(), elixir_type()}) |
    tuple() |
    struct() |
    nil

  @typedoc """
  Possible results from reading a BCS type
  """
  @type read_result() :: {:ok, BCS.elixir_type(), binary()} | {:error, term()}

  defdelegate decode(data, type), to: Decoder
  defdelegate read(data, type), to: Decoder
  defdelegate read_each(data, types), to: Decoder
  defdelegate read_seq(data, reader), to: Decoder
  defdelegate read_seq_fixed(data, len, reader), to: Decoder

  defdelegate encode(val, type), to: Encoder
  defdelegate write(data, val, type), to: Encoder
  defdelegate write_each(data, vals, types), to: Encoder
  defdelegate write_seq(data, vals, writer), to: Encoder
  defdelegate write_seq_fixed(data, vals, writer), to: Encoder

  @doc """
  Defines a schema for a BCS type. This macro sets up the necessary encoding and
  decoding functions based on the provided schema.
  """
  defmacro defschema(schema \\ []) do
    quote location: :keep do
      @behaviour Aldea.BCS.Encodable

      if length(unquote(schema)) > 0 do
        @impl Aldea.BCS.Encodable
        def bcs_read(data) when is_binary(data) do
          with {:ok, vals, rest} <- Aldea.BCS.read_each(data, Keyword.values(unquote(schema))) do
            params = Enum.zip([Keyword.keys(unquote(schema)), vals])
            case Kernel.function_exported?(__MODULE__, :__struct__, 0)  do
              true -> {:ok, struct(__MODULE__, params), rest}
              false -> {:ok, Enum.into(params, %{}), rest}
            end

          end
        end

        @impl Aldea.BCS.Encodable
        def bcs_write(data, val) when is_binary(data) do
          vals = Keyword.keys(unquote(schema)) |> Enum.map(& Map.get(val, &1))
          Aldea.BCS.write_each(data, vals, Keyword.values(unquote(schema)))
        end
      end

      defoverridable bcs_read: 1, bcs_write: 2
    end
  end

end
