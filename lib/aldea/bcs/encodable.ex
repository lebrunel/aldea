defmodule Aldea.BCS.Encodable do
  @moduledoc """
  TODO
  """

  @doc """
  TODO
  """
  @callback bcs_read(binary()) :: Aldea.BCS.read_result()

  @doc """
  TODO
  """
  @callback bcs_write(term(), term()) :: binary()

end
