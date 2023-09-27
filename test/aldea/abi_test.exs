defmodule Aldea.ABITest do
  use ExUnit.Case
  alias Aldea.ABI
  doctest Aldea.ABI

  @abi1 with {:ok, abi} <- ABI.from_json(File.read!("test/support/bcs1.abi.json")), do: abi
  @abi2 with {:ok, abi} <- ABI.from_json(File.read!("test/support/bcs2.abi.json")), do: abi

  test "foo" do
    assert {:ok, abi1} = ABI.to_bin(@abi1) |> ABI.from_bin()
    assert abi1 == @abi1
  end

  #test "foo" do
  #  {:ok, data} = File.read("test/support/pkg.abi.json")
  #  {:ok, abi} = ABI.from_json(data)
  #  IO.puts ABI.to_json(abi)
  #end

end
