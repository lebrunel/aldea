defmodule Aldea.Tx do
  @moduledoc """
  TODO
  """
  alias Aldea.Instruction

  defstruct version: 1, instructions: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    instructions: list(Instruction.t())
  }


end
