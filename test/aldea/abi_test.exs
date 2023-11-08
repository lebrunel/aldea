defmodule Aldea.ABITest do
  use ExUnit.Case
  alias Aldea.ABI
  doctest Aldea.ABI

  @abi1 with {:ok, abi} <- ABI.from_json(File.read!("test/support/bcs1.abi.json")), do: abi
  @abi2 with {:ok, abi} <- ABI.from_json(File.read!("test/support/bcs2.abi.json")), do: abi

  test "de/serializes ABI to/from binary" do
    assert {:ok, abi1} = ABI.to_bin(@abi1) |> ABI.from_bin()
    assert {:ok, abi2} = ABI.to_bin(@abi2) |> ABI.from_bin()
    assert abi1 == @abi1
    assert abi2 == @abi2
  end

  test "de/serializes ABI to/from json" do
    assert {:ok, abi1} = ABI.to_json(@abi1) |> ABI.from_json()
    assert {:ok, abi2} = ABI.to_json(@abi2) |> ABI.from_json()
    assert abi1 == @abi1
    assert abi2 == @abi2
  end

end
