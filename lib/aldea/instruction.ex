defmodule Aldea.Instruction do
  @moduledoc """
  An Instruction is Aldea's smallest contiguous unit of execution. An
  instruction consists of an `OpCode` byte and a number of attributes, depending
  on the `OpCode`.
  """
  alias Aldea.{
    BCS,
    Encodable,
  }
  import Aldea.Encoding, only: [
    varint_encode: 1,
    varint_parse_data: 1,
  ]

  defstruct op: nil, attrs: %{}

  @typedoc "Instruction"
  @type t() ::
    %__MODULE__{op: :IMPORT, attrs: %{pkg_id: <<_::256>>}} |
    %__MODULE__{op: :LOAD, attrs: %{output_id: <<_::256>>}} |
    %__MODULE__{op: :LOADBYORIGIN, attrs: %{origin: <<_::272>>}} |
    %__MODULE__{op: :NEW, attrs: %{idx: idx(), export_idx: idx(), args_data: binary()}} |
    %__MODULE__{op: :CALL, attrs: %{idx: idx(), method_idx: idx(), args_data: binary()}} |
    %__MODULE__{op: :EXEC, attrs: %{idx: idx(), export_idx: idx(), method_idx: idx(), args_data: binary()}} |
    %__MODULE__{op: :EXECFN, attrs: %{idx: idx(), export_idx: idx(), args_data: binary()}} |
    %__MODULE__{op: :FUND, attrs: %{idx: idx()}} |
    %__MODULE__{op: :LOCK, attrs: %{idx: idx(), pubkey_hash: <<_::160>>}} |
    %__MODULE__{op: :DEPLOY, attrs: %{entry: list(String.t()), code: pkg()}} |
    %__MODULE__{op: :SIGN, attrs: %{sig: <<_::512>>, pubkey: <<_::256>>}} |
    %__MODULE__{op: :SIGNTO, attrs: %{sig: <<_::512>>, pubkey: <<_::256>>}}

  @typedoc "Index"
  @type idx() :: non_neg_integer()

  @typedoc "Package"
  @type pkg() :: %{String.t() => String.t()}

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

  @doc """
  Returns a map ok known op codes to bytes.
  """
  @spec op_codes() :: map()
  def op_codes(), do: @op_codes

  @doc """
  Returns an Instruction from the given binary.
  """
  @spec from_bin(binary()) :: {:ok, t()} | {:error, term()}
  def from_bin(bin) when is_binary(bin) do
    with {:ok, instruction, <<>>} <- Serializable.parse(struct(__MODULE__), bin) do
      {:ok, instruction}
    end
  end

  @doc """
  Returns the Instruction as a binary.
  """
  @spec to_bin(t()) :: binary()
  def to_bin(%__MODULE__{} = instruction), do: Serializable.serialize(instruction)


  defimpl Encodable do
    alias Aldea.Instruction

    @impl true
    def read(instruction, bin) do
      with {:ok, op_code, bin} <- BCS.read(bin, :u8),
           {:ok, op} <- find_op_by_code(op_code),
           {:ok, attrs_bin, rest} <- BCS.read_bin(bin),
           attrs when is_map(attrs) <- parse_attrs(op, attrs_bin)
      do
        {:ok, struct(instruction, op: op, attrs: attrs), rest}
      end
    end

    @impl true
    def write(%{op: op, attrs: attrs}, bin) do
      bin
      |> BCS.write(:u8, Instruction.op_codes()[op])
      |> BCS.write_bin(serialize_attrs(op, attrs))
    end

    # Finds the op code by the byte.
    @spec find_op_by_code(non_neg_integer()) :: {:ok, atom()} | {:error, term()}
    defp find_op_by_code(op_code) do
      op_codes = Instruction.op_codes()
      case Enum.find(op_codes, fn {_key, val} -> val == op_code end) do
        {op, _code} -> {:ok, op}
        nil -> {:error, :invalid_op_code}
      end
    end

    # Parse the attributes from the given binary identified by the op code.
    @spec parse_attrs(atom(), binary()) :: map() | {:error, term()}
    defp parse_attrs(:IMPORT, pkg_id), do: %{pkg_id: pkg_id}
    defp parse_attrs(:LOAD, output_id), do: %{output_id: output_id}
    defp parse_attrs(:LOADBYORIGIN, origin), do: %{origin: origin}
    defp parse_attrs(:NEW, <<idx::little-16, export_idx::little-16, args_data::binary>>),
      do: %{idx: idx, export_idx: export_idx, args_data: args_data}
    defp parse_attrs(:CALL, <<idx::little-16, method_idx::little-16, args_data::binary>>),
      do: %{idx: idx, method_idx: method_idx, args_data: args_data}
    defp parse_attrs(:EXEC, <<idx::little-16, export_idx::little-16, method_idx::little-16, args_data::binary>>),
      do: %{idx: idx, export_idx: export_idx, method_idx: method_idx, args_data: args_data}
    defp parse_attrs(:EXECFN, <<idx::little-16, export_idx::little-16, args_data::binary>>),
      do: %{idx: idx, export_idx: export_idx, args_data: args_data}
    defp parse_attrs(:FUND, <<idx::little-16>>), do: %{idx: idx}
    defp parse_attrs(:LOCK, <<idx::little-16, pubkey_hash::binary-size(20)>>),
      do: %{idx: idx, pubkey_hash: pubkey_hash}
    defp parse_attrs(:DEPLOY, data) do
      with {:ok, [entry, code]} <- cbor_seq_decode(data) do
        %{entry: entry, code: code}
      end
    end
    defp parse_attrs(:SIGN, <<sig::binary-size(64), pubkey::binary-size(32)>>),
      do: %{sig: sig, pubkey: pubkey}
    defp parse_attrs(:SIGNTO, <<sig::binary-size(64), pubkey::binary-size(32)>>),
      do: %{sig: sig, pubkey: pubkey}

    # Serializes the attributes map into a binary.
    @spec serialize_attrs(atom(), map()) :: binary()
    defp serialize_attrs(:IMPORT, %{pkg_id: pkg_id}), do: pkg_id
    defp serialize_attrs(:LOAD, %{output_id: output_id}), do: output_id
    defp serialize_attrs(:LOADBYORIGIN, %{origin: origin}), do: origin
    defp serialize_attrs(:NEW, %{idx: idx, export_idx: export_idx, args: args}) do
      <<idx::little-16, export_idx::little-16, cbor_seq_encode(args)::binary>>
    end
    defp serialize_attrs(:CALL, %{idx: idx, method_idx: method_idx, args: args}) do
      <<idx::little-16, method_idx::little-16, cbor_seq_encode(args)::binary>>
    end
    defp serialize_attrs(:EXEC, %{idx: idx, export_idx: export_idx, method_idx: method_idx, args: args}) do
      <<idx::little-16, export_idx::little-16, method_idx::little-16, cbor_seq_encode(args)::binary>>
    end
    defp serialize_attrs(:EXECFN, %{idx: idx, export_idx: export_idx, args: args}) do
      <<idx::little-16, export_idx::little-16, cbor_seq_encode(args)::binary>>
    end
    defp serialize_attrs(:FUND, %{idx: idx}), do: <<idx::little-16>>
    defp serialize_attrs(:LOCK, %{idx: idx, pubkey_hash: pubkey_hash}) do
      <<idx::little-16, pubkey_hash::binary>>
    end
    defp serialize_attrs(:DEPLOY, %{entry: entry, code: code}) do
      cbor_seq_encode([entry, code])
    end
    defp serialize_attrs(:SIGN, %{sig: sig, pubkey: pubkey}) do
      <<sig::binary, pubkey::binary>>
    end
    defp serialize_attrs(:SIGNTO, %{sig: sig, pubkey: pubkey}) do
      <<sig::binary, pubkey::binary>>
    end
  end

end
