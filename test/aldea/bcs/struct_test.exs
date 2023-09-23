defmodule Aldea.BCS.StructTest do
  use ExUnit.Case
  alias Aldea.BCS
  doctest Aldea.BCS.Struct

  defmodule Test do
    use Aldea.BCS.Struct

    bcs_struct do
      field :foo, :u32
      field :bar, :u32
    end
  end

  test "module has BCS read/write methods dynamically added" do
    assert Kernel.function_exported?(Test, :bcs_read, 1)
    assert Kernel.function_exported?(Test, :bcs_write, 2)
  end

  test "read and write round trip" do
    item = %Test{foo: 100, bar: 200}
    assert {:ok, ^item, ""} = Test.bcs_write("", item) |> Test.bcs_read()
  end

end
