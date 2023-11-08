defmodule Aldea.BCSTest do
  use ExUnit.Case
  alias Aldea.BCS
  doctest Aldea.BCS

  @test_data %{
    seq: [100, 200, 300, 400],
    map: %{1 => 100, 2 => 200, 3 => 300, 4 => 400},
    # we can encode an elixir tuple, but read/2 aways returns a list
    tuple: [180, "hello", 30123],
    struct: %{foo: 500000, bar: "hello", baz: [1,2,3,4]}
  }

  @test_types %{
    tuple: {:tuple, [:u32, {:bin, 5}, :u32]},
    struct: {:struct, [{:foo, :u32}, {:bar, :bin}, {:baz, {:seq, :u8}}]}
  }

  describe "encode/2 and decode/2 roundtrip" do
    test "booleans" do
      assert {:ok, true} = BCS.encode(true, :bool) |> BCS.decode(:bool)
      assert {:ok, false} = BCS.encode(false, :bool) |> BCS.decode(:bool)
    end

    test "floats" do
      assert {:ok, 3.14159265358979323846} = BCS.encode(3.14159265358979323846, :f64) |> BCS.decode(:f64)
    end

    test "signed ints" do
      assert {:ok, -123} = BCS.encode(-123, :i8) |> BCS.decode(:i8)
      assert {:ok, -1234} = BCS.encode(-1234, :i16) |> BCS.decode(:i16)
      assert {:ok, -12345678} = BCS.encode(-12345678, :i32) |> BCS.decode(:i32)
      assert {:ok, -1234567890123456} = BCS.encode(-1234567890123456, :i64) |> BCS.decode(:i64)
    end

    test "unsigned ints" do
      assert {:ok, 234} = BCS.encode(234, :u8) |> BCS.decode(:u8)
      assert {:ok, 23456} = BCS.encode(23456, :u16) |> BCS.decode(:u16)
      assert {:ok, 23456789} = BCS.encode(23456789, :u32) |> BCS.decode(:u32)
      assert {:ok, 2345678901234567} = BCS.encode(2345678901234567, :u64) |> BCS.decode(:u64)
    end

    test "ulebs" do
      assert {:ok, 100} = BCS.encode(100, :uleb) |> BCS.decode(:uleb)
      assert {:ok, 200} = BCS.encode(200, :uleb) |> BCS.decode(:uleb)
      assert {:ok, 12345678901234567890} = BCS.encode(12345678901234567890, :uleb) |> BCS.decode(:uleb)
    end

    test "binary strings" do
      assert {:ok, "hello"} = BCS.encode("hello", :bin) |> BCS.decode(:bin)
      assert {:ok, "hello"} = BCS.encode("hello", {:bin, 5}) |> BCS.decode({:bin, 5})
    end

    test "options" do
      assert {:ok, 30123} = BCS.encode(30123, {:option, :u32}) |> BCS.decode({:option, :u32})
      assert {:ok, nil} = BCS.encode(nil, {:option, :u32}) |> BCS.decode({:option, :u32})
    end

    test "sequences" do
      seq_data = @test_data[:seq]
      assert {:ok, ^seq_data} = BCS.encode(seq_data, {:seq, :u32}) |> BCS.decode({:seq, :u32})
      assert {:ok, ^seq_data} = BCS.encode(seq_data, {:seq, 4, :u32}) |> BCS.decode({:seq, 4, :u32})
    end

    test "maps" do
      map_data = @test_data[:map]
      assert {:ok, ^map_data} = BCS.encode(map_data, {:map, {:u32, :u32}}) |> BCS.decode({:map, {:u32, :u32}})
      assert {:ok, ^map_data} = BCS.encode(map_data, {:map, 4, {:u32, :u32}}) |> BCS.decode({:map, 4, {:u32, :u32}})
    end

    test "tuples" do
      tuple_data = @test_data[:tuple]
      assert {:ok, ^tuple_data} = BCS.encode(tuple_data, @test_types[:tuple]) |> BCS.decode(@test_types[:tuple])
    end

    test "structs" do
      struct_data = @test_data[:struct]
      assert {:ok, ^struct_data} = BCS.encode(struct_data, @test_types[:struct]) |> BCS.decode(@test_types[:struct])
    end
  end

  describe "encode/2 byte size" do
    test "booleans" do
      assert BCS.encode(true, :bool) |> byte_size() == 1
    end

    test "floats" do
      assert BCS.encode(3.14159265358979323846, :f64) |> byte_size() == 8
    end

    test "signed ints" do
      assert BCS.encode(-123, :i8) |> byte_size() == 1
      assert BCS.encode(-1234, :i16) |> byte_size() == 2
      assert BCS.encode(-12345678, :i32) |> byte_size() == 4
      assert BCS.encode(-1234567890123456, :i64) |> byte_size() == 8
    end

    test "unsigned ints" do
      assert BCS.encode(23, :u8) |> byte_size() == 1
      assert BCS.encode(23456, :u16) |> byte_size() == 2
      assert BCS.encode(23456789, :u32) |> byte_size() == 4
      assert BCS.encode(2345678901234567, :u64) |> byte_size() == 8
    end

    test "ulebs" do
      assert BCS.encode(100, :uleb) |> byte_size() == 1
      assert BCS.encode(200, :uleb) |> byte_size() == 2
      assert BCS.encode(12345678901234567890, :uleb) |> byte_size() == 10
    end

    test "binary strings" do
      assert BCS.encode("hello", :bin) |> byte_size() == 6
      assert BCS.encode("hello", {:bin, 5}) |> byte_size() == 5
    end

    test "options" do
      assert BCS.encode(30123, {:option, :u32}) |> byte_size() == 5
      assert BCS.encode(nil, {:option, :u32}) |> byte_size() == 1
    end

    test "sequences" do
      assert BCS.encode(@test_data[:seq], {:seq, :u32}) |> byte_size() == 17
      assert BCS.encode(@test_data[:seq], {:seq, 4, :u32}) |> byte_size() == 16
    end

    test "maps" do
      assert BCS.encode(@test_data[:map], {:map, {:u32, :u32}}) |> byte_size() == 33
      assert BCS.encode(@test_data[:map], {:map, 4, {:u32, :u32}}) |> byte_size() == 32
    end

    test "tuples" do
      assert BCS.encode(@test_data[:tuple], @test_types[:tuple]) |> byte_size() == 13
    end

    test "structs" do
      assert BCS.encode(@test_data[:struct], @test_types[:struct]) |> byte_size() == 15
    end
  end

  # todo
  # - test encoding non boolean value
  # - test encoding fixed binaries with wrong length
  # - test encoding fixed sequences with wrong length

  # - test encoding elixir maps and lists of key/vals
  # - test encoding elixir tuples and lists of vals

  # - test detrministic oredring of structs

end
