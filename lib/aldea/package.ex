defmodule Aldea.Package do
  @moduledoc """
  TODO
  """
  alias Aldea.BCS

  defstruct entries: [], code: %{}

  #BCS.defencodable do
  #  field :entries, {:list, :bin}
  #  field :code, {:map, {:bin, :bin}}
  #end

  defimpl BCS.Encodable do
    @impl true
    def read(pkg, data) do
      with {:ok, entries, data} <- BCS.read(data, {:list, :bin}),
           {:ok, code, rest} <- BCS.read(data, {:map, {:bin, :bin}})
      do
        {:ok, struct(pkg, [
          entries: entries,
          code: code,
        ]), rest}
      end
    end


  end

end
