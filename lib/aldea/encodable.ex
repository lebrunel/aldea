defprotocol Aldea.Encodable do
  @moduledoc """
  TODO
  """

  @doc """
  TODO
  """
  @spec read(t(), binary()) :: {:ok, t(), binary()} | {:error, term()}
  def read(type, data)

  @doc """
  TODO
  """
  @spec write(t(), binary()) :: binary()
  def write(type, data \\ <<>>)

end
