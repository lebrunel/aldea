defmodule Aldea.PackageTest do
  use ExUnit.Case
  alias Aldea.Package
  doctest Aldea.Package

  @pkg %Package{
    entry: ["main.ts"],
    code: %{
      "main.ts" => "export function foo(): bool { return true }"
    }
  }

  test "encode decode rountrip" do
    {:ok, pkg} = Package.to_bin(@pkg) |> Package.from_bin()
    assert pkg == @pkg
  end

end
