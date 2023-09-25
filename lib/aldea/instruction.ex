defmodule Aldea.Instruction do
  require Record
  alias Aldea.BCS

  @behaviour BCS.Encodable

  Record.defrecord(:import_instruction, :IMPORT, pkg_id: nil)
  Record.defrecord(:load_instruction, :LOAD, output_id: nil)
  Record.defrecord(:loadbyorigin_instruction, :LOADBYORIGIN, origin: nil)
  Record.defrecord(:new_instruction, :NEW, idx: nil, export_idx: nil, arg_data: nil)
  Record.defrecord(:call_instruction, :CALL, idx: nil, method_idx: nil, arg_data: nil)
  Record.defrecord(:exec_instruction, :EXEC, idx: nil, export_idx: nil, method_idx: nil, arg_data: nil)
  Record.defrecord(:execfunc_instruction, :EXECFN, idx: nil, export_idx: nil, arg_data: nil)
  Record.defrecord(:fund_instruction, :FUND, idx: nil)
  Record.defrecord(:lock_instruction, :LOCK, idx: nil, pubkey_hash: nil)
  Record.defrecord(:deploy_instruction, :DEPLOY, pkg_data: nil)
  Record.defrecord(:sign_instruction, :SIGN, sig: nil, pubkey: nil)
  Record.defrecord(:signto_instruction, :SIGNTO, sig: nil, pubkey: nil)

  defguard is_instruction(input)
    when Record.is_record(input, :IMPORT)
    or Record.is_record(input, :LOAD)
    or Record.is_record(input, :LOADBYORIGIN)
    or Record.is_record(input, :NEW)
    or Record.is_record(input, :CALL)
    or Record.is_record(input, :EXEC)
    or Record.is_record(input, :EXECFN)
    or Record.is_record(input, :FUND)
    or Record.is_record(input, :LOCK)
    or Record.is_record(input, :DEPLOY)
    or Record.is_record(input, :SIGN)
    or Record.is_record(input, :SIGNTO)

  @typedoc "TODO"
  @type t ::
    import_instruction |
    load_instruction |
    loadbyorigin_instruction |
    new_instruction |
    call_instruction |
    exec_instruction |
    execfunc_instruction |
    fund_instruction |
    lock_instruction |
    deploy_instruction |
    sign_instruction |
    signto_instruction

  @type import_instruction :: record(:import_instruction, pkg_id: <<_::256>>)
  @type load_instruction :: record(:load_instruction, output_id: <<_::256>>)
  @type loadbyorigin_instruction :: record(:loadbyorigin_instruction, origin: <<_::272>>)
  @type new_instruction :: record(:new_instruction, idx: integer, export_idx: integer, arg_data: binary)
  @type call_instruction :: record(:call_instruction, idx: integer, method_idx: integer, arg_data: binary)
  @type exec_instruction :: record(:exec_instruction, idx: integer, export_idx: nil, method_idx: integer, arg_data: binary)
  @type execfunc_instruction :: record(:execfunc_instruction, idx: integer, export_idx: integer, arg_data: binary)
  @type fund_instruction :: record(:fund_instruction, idx: integer)
  @type lock_instruction :: record(:lock_instruction, idx: integer, pubkey_hash: <<_::256>>)
  @type deploy_instruction :: record(:deploy_instruction, pkg_data: binary)
  @type sign_instruction :: record(:sign_instruction, sig: <<_::512>>, pubkey: <<_::256>>)
  @type signto_instruction :: record(:signto_instruction, sig: <<_::512>>, pubkey: <<_::256>>)

  @op_codes %{
    # Loading
    IMPORT: 0xA1,
    LOAD: 0xA2,
    LOADBYORIGIN: 0xA3,
    # Calling
    NEW: 0xB1,
    CALL: 0xB2,
    EXEC: 0xB3,
    EXECFN: 0xB4,
    # Output
    FUND: 0xC1,
    LOCK: 0xC2,
    # Code
    DEPLOY: 0xD1,
    # Cryptography
    SIGN: 0xE1,
    SIGNTO: 0xE2,
  }

  @bcs_schemas %{
    # Loading
    IMPORT: [{:bin, 32}],
    LOAD: [{:bin, 32}],
    LOADBYORIGIN: [{:bin, 34}],
    # Calling
    NEW: [:u16, :u16, {:bin, :fixed}],
    CALL: [:u16, :u16, {:bin, :fixed}],
    EXEC: [:u16, :u16, :u16, {:bin, :fixed}],
    EXECFN: [:u16, :u16, {:bin, :fixed}],
    # Output
    FUND: [:u16],
    LOCK: [:u16, {:bin, 20}],
    # Code
    DEPLOY: [{:bin, :fixed}],
    # Cryptography
    SIGN: [{:bin, 64}, {:bin, 32}],
    SIGNTO: [{:bin, 64}, {:bin, 32}],
  }

  @doc """
  TODO
  """
  @spec op_codes() :: map()
  def op_codes(), do: @op_codes

  @doc """
  TODO
  """
  @spec find_opcode(atom() | non_neg_integer()) :: {atom(), non_neg_integer()} | {:error, term}
  def find_opcode(key) when is_atom(key),
    do: Enum.find(@op_codes, {:error, :unknown_opcode}, fn {k, _v} -> k == key end)
  def find_opcode(byte) when is_integer(byte),
    do: Enum.find(@op_codes, {:error, :unknown_opcode}, fn {_k, v} -> v == byte end)

  @doc """
  TODO
  """
  @spec from_bin(binary) :: {:ok, t} | {:error, term}
  def from_bin(data) when is_binary(data) do
    with {:ok, instruction, _rest} <- bcs_read(data), do: {:ok, instruction}
  end

  @doc """
  TODO
  """
  @spec to_bin(t) :: binary
  def to_bin(instruction) when is_instruction(instruction),
    do: bcs_write(<<>>, instruction)

  @doc """
  TODO
  """
  @spec bcs_read(binary) :: BCS.read_result()
  def bcs_read(data) when is_binary(data) do
    with {:ok, byte, data} <- BCS.read(data, :u8),
         {opcode, ^byte} <- find_opcode(byte),
         {:ok, instruction_data, rest} <- BCS.read(data, :bin),
         {:ok, fields} <- BCS.decode(instruction_data, {:tuple, @bcs_schemas[opcode]})
    do
      {:ok, List.to_tuple([opcode | fields]), rest}
    end
  end

  @doc """
  TODO
  """
  @spec bcs_write(binary, t) :: binary
  def bcs_write(data, instruction) when is_binary(data) and is_instruction(instruction) do
    opcode = elem(instruction, 0)

    instruction_data =
      instruction
      |> Tuple.delete_at(0)
      |> BCS.encode({:tuple, @bcs_schemas[opcode]})

    data
    |> BCS.write(@op_codes[opcode], :u8)
    |> BCS.write(instruction_data, :bin)
  end

end
