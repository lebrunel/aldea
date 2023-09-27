defmodule CanonicalsTest do
  use ExUnit.Case
  require Record
  alias Aldea.{
    ABI,
    Address,
    #HDPrivKey,
    #HDPubKey,
    Package,
    PrivKey,
    PubKey,
    Tx,
  }

  @pkg_abi with {:ok, abi} <- ABI.from_json(File.read!("test/support/pkg.abi.json")), do: abi
  @coin_abi with {:ok, abi} <- ABI.from_json(File.read!("test/support/coin.abi.json")), do: abi

  @keys %{
    privkey: "asec1f40sdqzmph3ec7uce9lu97zc2yadh7hs6ut2j37pryjf0zjgp45srd6f6z",
    pubkey: "apub1ae6x0x0jrzw2z0dtk73knewry8f04sduw2g5gzquu4puvqfrl7jswd84n8",
    address: "addr1x8xyadtsgfdrjw2dw6qzh269eqjtf5q5gj7zwm",
  }

  @tx %{
    txid: "2515600592b985411f7c4fb51a647e28ab8774c34b9429fe99dc7ba9af130ba6",
    rawtx: "01000ea120a0b07c4143ae6f105ea79cff5d21d2d1cd09351cf66e41c3e43bfb3bddb1a701a220df4cf424923ad248766251066fa4a408930faf94fff66c77657e79f604d3120da322675d72e2d567cbe2cb9ef3230cbc4c85e42bcd56ba537f6b65a51b9c6c8552810100b109000000000003666f6fb2220100010000bc0200000000000014f8be00b23c9c1c30720e862d00082121d83c4ff3b209020001000003626172b30b00000000020000036d756db409000001000003646164c1020100c2160200f8be00b23c9c1c30720e862d00082121d83c4ff3c2160300f8be00b23c9c1c30720e862d00082121d83c4ff3d15f0108696e6465782e74730108696e6465782e74734a6578706f72742066756e6374696f6e2068656c6c6f576f726c64286d73673a20737472696e67293a20737472696e67207b2072657475726e206048656c6c6f20247b6d73677d2160207de16037087bc4b4306c458d79e03c271d8a49578313644ab11bff4998354ab9209a937d173ca1b7dc44e814df3864f1f1a9c7771bb8d38fbeab18d09432acca3d1c09a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961e26019946de3804c1450b09963e9868347cdb0a1c79df416afa09b6a081fd49944ba6d4dce1cc3bb8b6f06c807a2984e043e686758fb8ea49589fb5ae86f06864d0ca19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961",
    instructions: [
      {:IMPORT,       Base.decode16!("a0b07c4143ae6f105ea79cff5d21d2d1cd09351cf66e41c3e43bfb3bddb1a701", case: :lower)},
      {:LOAD,         Base.decode16!("df4cf424923ad248766251066fa4a408930faf94fff66c77657e79f604d3120d", case: :lower)},
      {:LOADBYORIGIN, Base.decode16!("675d72e2d567cbe2cb9ef3230cbc4c85e42bcd56ba537f6b65a51b9c6c8552810100", case: :lower)},
      {:NEW,          0, 0, ABI.encode(@pkg_abi, "Badge_constructor", ["foo"])},
      {:CALL,         1, 1, ABI.encode(@coin_abi, "Coin$send", [700, Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)])},
      {:CALL,         2, 1, ABI.encode(@pkg_abi, "Badge$rename", ["bar"])},
      {:EXEC,         0, 0, 2, ABI.encode(@pkg_abi, "Badge_helloWorld", ["mum"])},
      {:EXECFN,       0, 1, ABI.encode(@pkg_abi, "helloWorld", ["dad"])},
      {:FUND,         1},
      {:LOCK,         2, Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)},
      {:LOCK,         3, Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)},
      {:DEPLOY,       Package.to_bin(%Package{entry: ["index.ts"], code: %{"index.ts" => "export function helloWorld(msg: string): string { return `Hello ${msg}!` }"}})},
      {:SIGN,         "", Base.decode16!("a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961", case: :lower)},
      {:SIGNTO,       "", Base.decode16!("a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961", case: :lower)},
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
    for {a, b} <- Enum.zip(tx.instructions, @tx.instructions) do
      if elem(a, 0) in [:SIGN, :SIGNTO] do
        assert elem(a, 2) == elem(b, 2)
      else
        assert a == b
      end
    end
    assert Tx.to_hex(tx) == @tx.rawtx
    assert Tx.verify(tx)
  end

end
