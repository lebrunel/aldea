defmodule CanonicalsTest do
  use ExUnit.Case
  alias Aldea.{
    Address,
    #HDPrivKey,
    #HDPubKey,
    PrivKey,
    PubKey,
    Tx,
  }

  @keys %{
    privkey: "asec1f40sdqzmph3ec7uce9lu97zc2yadh7hs6ut2j37pryjf0zjgp45srd6f6z",
    pubkey: "apub1ae6x0x0jrzw2z0dtk73knewry8f04sduw2g5gzquu4puvqfrl7jswd84n8",
    address: "addr1x8xyadtsgfdrjw2dw6qzh269eqjtf5q5gj7zwm",
  }

  @tx %{
    txid: "807b383891e03cb5b7943e4bce45b443d96e13ea94907d42aa30f15082bae5af",
    rawtx: "01000ea120a0b07c4143ae6f105ea79cff5d21d2d1cd09351cf66e41c3e43bfb3bddb1a701a220df4cf424923ad248766251066fa4a408930faf94fff66c77657e79f604d3120da322675d72e2d567cbe2cb9ef3230cbc4c85e42bcd56ba537f6b65a51b9c6c8552810100b109000000000003666f6fb2220100010000bc0200000000000014f8be00b23c9c1c30720e862d00082121d83c4ff3b209020001000003626172b30b00000000020000036d756db409000001000003646164c1020100c2160200f8be00b23c9c1c30720e862d00082121d83c4ff3c2160300f8be00b23c9c1c30720e862d00082121d83c4ff3d15f0108696e6465782e74730108696e6465782e74734a6578706f72742066756e6374696f6e2068656c6c6f576f726c64286d73673a20737472696e67293a20737472696e67207b2072657475726e206048656c6c6f20247b6d73677d2160207de160cd90e6b96d194bd5e3243dcbe5b9166471571167d63a05c4453717f55da6f30e32c4ad195714e4b96ee319fd8651639187c323f9155abd29956f93a309474809a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961e2607d16262204d80dc33c773a7e246e53ce0abcdedfd1bf5a036244b6c413286decad879720d96847cad5c9e9df54ab786d45cdeac274a011c09e9f28a3a6cba401a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961",
    instructions: [
      {:IMPORT,       Base.decode16!("a0b07c4143ae6f105ea79cff5d21d2d1cd09351cf66e41c3e43bfb3bddb1a701", case: :lower)},
      {:LOAD,         Base.decode16!("df4cf424923ad248766251066fa4a408930faf94fff66c77657e79f604d3120d", case: :lower)},
      {:LOADBYORIGIN, Base.decode16!("675d72e2d567cbe2cb9ef3230cbc4c85e42bcd56ba537f6b65a51b9c6c8552810100", case: :lower)},
      {:NEW,          0, 0, ["foo"]},
      {:CALL,         1, 1, [700, Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)]},
      {:CALL,         2, 1, ["bar"]},
      {:EXEC,         0, 0, 2, ["mum"]},
      {:EXECFN,       0, 1, ["dad"]},
      {:FUND,         1},
      {:LOCK,         2, Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)},
      {:LOCK,         3, Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)},
      {:DEPLOY,       %{entry: ["index.ts"], code: %{"index.ts" => "export function helloWorld(msg: string): string { return `Hello ${msg}!` }"}}},
      {:SIGN,         Base.decode16!("dcec284f6257490225aec9762c2b4f4683841fd76a8c67407ce58058019688f27c51945b3055e3b9c652bfddc6b2c696a9130b8159de1f9f1de31ac17693ff0f", case: :lower), pubkey: Base.decode16!("a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961", case: :lower)},
      {:SIGNTO,       Base.decode16!("db7134476827db2c4c096b25e3fa67e2759e295108cb676f455e354d4c984ede577daeedc097296e6b894e5f6581234be085264262a30867aff04980000ab502", case: :lower), pubkey: Base.decode16!("a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961", case: :lower)},
    ]
  }

  test "Canonical priv and pub key and address serialisation" do
    assert {:ok, privkey} = PrivKey.from_string(@keys.privkey)
    assert {:ok, pubkey} = PubKey.from_string(@keys.pubkey)

    assert PubKey.from_privkey(privkey) |> PubKey.to_string() == @keys.pubkey
    assert PubKey.from_privkey(privkey) |> Address.from_pubkey() |> Address.to_string() == @keys.address
    assert Address.from_pubkey(pubkey) |> Address.to_string() == @keys.address
  end

  test "Kitchen sink serialisation" do
    assert {:ok, tx} = Tx.from_hex(@tx.rawtx)
    assert length(tx.instructions) == 14
    #for {inst, {op, attrs}} <- Enum.zip(tx.instructions, @tx.instructions) do
    #  assert inst.op == op
    #  assert inst.attrs == attrs
    #end
    assert Tx.to_hex(tx) == @tx.rawtx
  end

end
