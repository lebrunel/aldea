defmodule Aldea.Tx do
  @moduledoc """
  TODO
  """
  alias Aldea.{
    Instruction,
    Serializable,
  }
  import Aldea.Encoding, only: [
    #bin_decode: 2,
    #bin_encode: 2,
    varint_encode: 1,
    varint_parse_structs: 2,
  ]

  defstruct version: 1, instructions: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    instructions: list(Instruction.t())
  }

  defimpl Serializable do
    @impl true
    def parse(tx, data) do
      with <<version::little-16, data::binary>> <- data,
           {:ok, instructions, rest} <- varint_parse_structs(data, Instruction)
      do
        {:ok, struct(tx, [version: version, instructions: instructions]), rest}
      end
    end

    @impl true
    def serialize(tx) do
      data = <<tx.version::little-16>> <> varint_encode(length(tx.instructions))
      Enum.reduce(tx.instructions, data, fn inst, bin ->
        bin <> Serializable.serialize(inst)
      end)
    end
  end

end
