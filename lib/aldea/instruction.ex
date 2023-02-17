defmodule Aldea.Instruction do
  @moduledoc """
  TODO
  """
  import Record

  defrecord(:import_inst, :IMPORT, pkg_id: nil)
  defrecord(:load_inst, :LOAD, output_id: nil)
  defrecord(:load_by_origin_inst, :LOADBYORIGIN, origin: nil)
  defrecord(:new_inst, :NEW, idx: nil, export_idx: nil, args: [])
  defrecord(:call_inst, :CALL, idx: nil, method_idx: nil, args: [])
  defrecord(:exec_inst, :EXEC, idx: nil, export_idx: nil, method_idx: nil, args: [])
  defrecord(:exec_func_inst, :EXECFUNC, idx: nil, export_idx: nil, args: [])
  defrecord(:fund_inst, :FUND, idx: nil)
  defrecord(:lock_inst, :LOCK, idx: nil, pubkey_hash: nil)
  defrecord(:deploy_inst, :DEPLOY, entry: nil, code: nil)
  defrecord(:sign_inst, :SIGN, sig: nil, pubkey: nil)
  defrecord(:sign_to_inst, :SIGNTO, sig: nil, pubkey: nil)

  @typedoc "TODO"
  @type t() ::
    import_inst() |
    load_inst() |
    load_by_origin_inst() |
    new_inst() |
    call_inst() |
    exec_inst() |
    exec_func_inst() |
    fund_inst() |
    lock_inst() |
    deploy_inst() |
    sign_inst() |
    sign_to_inst()

  @typedoc "TODO"
  @type idx() :: non_neg_integer()
  @typedoc "TODO"
  @type pkg() :: %{String.t() => String.t()}
  @typedoc "IMPORT instruction"
  @type import_inst() :: record(:import_inst, pkg_id: binary())
  @typedoc "LOAD instruction"
  @type load_inst() :: record(:load_inst, output_id: binary())
  @typedoc "LOADBYORIGIN instruction"
  @type load_by_origin_inst() :: record(:load_by_origin_inst, origin: binary())
  @typedoc "NEW instruction"
  @type new_inst() :: record(:new_inst, idx: idx(), export_idx: idx(), args: list(any()))
  @typedoc "CALL instruction"
  @type call_inst() :: record(:call_inst, idx: idx(), method_idx: idx(), args: list(any()))
  @typedoc "EXEC instruction"
  @type exec_inst() :: record(:exec_inst, idx: idx(), export_idx: idx(), method_idx: idx(), args: list(any()))
  @typedoc "EXECFUNC instruction"
  @type exec_func_inst() :: record(:exec_func_inst, idx: idx(), export_idx: idx(), args: list(any()))
  @typedoc "FUND instruction"
  @type fund_inst() :: record(:fund_inst, idx: idx())
  @typedoc "LOCK instruction"
  @type lock_inst() :: record(:lock_inst, idx: idx(), pubkey_hash: binary())
  @typedoc "DEPLOY instruction"
  @type deploy_inst() :: record(:deploy_inst, entry: list(String.t()), code: pkg())
  @typedoc "SIGN instruction"
  @type sign_inst() :: record(:sign_inst, sig: binary(), pubkey: binary())
  @typedoc "SIGNTO instruction"
  @type sign_to_inst() :: record(:sign_to_inst, sig: binary(), pubkey: binary())

  @op_codes %{
    # Loading
    IMPORT: 0xA1,
    LOAD: 0xA2,
    LOADBYORIGIN: 0xA3,
    # Calling
    NEW: 0xB1,
    CALL: 0xB2,
    EXEC: 0xB3,
    EXECFUNC: 0xB4,
    # Output
    FUND: 0xC1,
    LOCK: 0xC2,
    # Code
    DEPLOY: 0xD1,
    # Cryptography
    SIGN: 0xE1,
    SIGNTO: 0xE2,
  }



end
