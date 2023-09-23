defmodule Aldea.BCS do
  @moduledoc """
  TODO
  """
  alias Aldea.BCS.{Decoder, Encoder}

  @typedoc "TODO"
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

  @typedoc "TODO"
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

  @typedoc "TODO"
  @type read_result() :: {:ok, BCS.elixir_type(), binary()} | {:error, term()}

  defdelegate decode(data, type), to: Decoder
  defdelegate read(data, type), to: Decoder
  defdelegate read_each(data, types), to: Decoder
  defdelegate read_seq(data, reader), to: Decoder
  defdelegate read_seq_fixed(data, len, reader), to: Decoder

  defdelegate encode(type, val), to: Encoder
  defdelegate write(data, type, val), to: Encoder
  defdelegate write_each(data, types, vals), to: Encoder
  defdelegate write_seq(data, vals, writer), to: Encoder
  defdelegate write_seq_fixed(data, vals, writer), to: Encoder

end
