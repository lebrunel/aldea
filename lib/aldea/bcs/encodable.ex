defmodule Aldea.BCS.Encodable do
  @moduledoc """
  A module that provides an interface for encoding and decoding data in the BCS
  (Binary Canonical Serialization) format.
  """

  @doc """
  Reads a binary and decodes it into a term.
  """
  @callback bcs_read(binary()) :: Aldea.BCS.read_result()

  @doc """
  Encodes a term into a binary.
  """
  @callback bcs_write(term(), term()) :: binary()

end
