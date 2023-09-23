defmodule CanonicalsTest do
  use ExUnit.Case
  alias Aldea.{
    Address,
    HDPrivKey,
    HDPubKey,
    PrivKey,
    PubKey,
    Tx,
  }

  @keys %{
    privkey: "asec1f40sdqzmph3ec7uce9lu97zc2yadh7hs6ut2j37pryjf0zjgp45srd6f6z",
    pubkey: "apub1ae6x0x0jrzw2z0dtk73knewry8f04sduw2g5gzquu4puvqfrl7jswd84n8",
    address: "addr1x8xyadtsgfdrjw2dw6qzh269eqjtf5q5gj7zwm",
  }

  @hd_keys %{
    seed: "air above edge runway time admit escape improve glad tissue burden scale",
    root_priv: "xsec1qr44uvl2jpu7u25wnlrcm2x8dvdqxqm4k4vpycufj3k2wvzu5426le4sp8w7q2ma2hj82pe9cueaffs8xx2eycry64kd48crhq4a2c6ffzs07509xnn86yqz574zsnn88s8t7zd0npd42ku0rkgyaa5epyezrywe",
    root_pub: "xpub1r5zfwsd7q0avgl4watqccuvqu5mjszejss3c28ukr389syergce5jj9qlag72d8x05gq9fa29p8xw0qwhuy6lxzm24dc78vsfmmfjzg0e6j4f",
    child: %{
      path: "m/1/2/3/4",
      priv: "xsec1jp4gasqd6y0l5w9659vw5jtxed3k9a8r699jklzhv4m8v0ju5426ermksh60csthg5kjgstf2mzgs3a3t4saea4pr0hzcg34ku57n8w8vlvpxej3d8m76zzu4pm7l3hmp45yr97xxmdx2ccz9duqjz2fqslnlsaj",
      pub: "xpub1wmsgv4zjs4gvtkls85p9hx33zw036ndrpnyyg34x2kydjw0wczmvwe7czdn9z60ha5y9e2rhalr0krtggxtuvdk6v43sy2mcpyy5jpqasysut",
      addr: "addr1t66yrtwuka6nvw0dcydd62justftrach3g6fmx",
    },
    hard_child: %{
      path: "m/1h/2h/3/4",
      priv: "xsec1wzyqvpy7y8xcw9vv99wejrluvpua39t30fevdezrz3qu5sju542lxy4d3j795kfszpaz9jkdjz96f7xktlkm29fuz65s9jathpe8p3lsgxauc75nzm4z0m9dum9yhmr6cf4m7z283urrgtehjpjgtn2e0ul4c8rk",
      pub: "xpub1egr5ejcv5fr0gx0jaktugn687kjlsr95p8atgx3hnwhfyhst8w7lqsdme3afx9h2ylk2mek2f0k84snthuy50rcxxshn0yryshx4jlc3uycuv",
      addr: "addr125y02awwkjgj5vg3v3vxv2g44pywluer4jern9",
    }
  }

  @tx %{
    rawtx: "01000ea120a0b07c4143ae6f105ea79cff5d21d2d1cd09351cf66e41c3e43bfb3bddb1a701a220df4cf424923ad248766251066fa4a408930faf94fff66c77657e79f604d3120da322675d72e2d567cbe2cb9ef3230cbc4c85e42bcd56ba537f6b65a51b9c6c8552810100b1080000000063666f6fb21e010001001902bcd84054f8be00b23c9c1c30720e862d00082121d83c4ff3b2080200010063626172b30a000000000200636d756db4080000010063646164c1020100c2160200f8be00b23c9c1c30720e862d00082121d83c4ff3c2160300f8be00b23c9c1c30720e862d00082121d83c4ff3d1608168696e6465782e7473a168696e6465782e7473784a6578706f72742066756e6374696f6e2068656c6c6f576f726c64286d73673a20737472696e67293a20737472696e67207b2072657475726e206048656c6c6f20247b6d73677d2160207de160dcec284f6257490225aec9762c2b4f4683841fd76a8c67407ce58058019688f27c51945b3055e3b9c652bfddc6b2c696a9130b8159de1f9f1de31ac17693ff0fa19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961e260db7134476827db2c4c096b25e3fa67e2759e295108cb676f455e354d4c984ede577daeedc097296e6b894e5f6581234be085264262a30867aff04980000ab502a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961",
    instructions: [
      {:IMPORT,       %{pkg_id: Base.decode16!("a0b07c4143ae6f105ea79cff5d21d2d1cd09351cf66e41c3e43bfb3bddb1a701", case: :lower)}},
      {:LOAD,         %{output_id: Base.decode16!("df4cf424923ad248766251066fa4a408930faf94fff66c77657e79f604d3120d", case: :lower)}},
      {:LOADBYORIGIN, %{origin: Base.decode16!("675d72e2d567cbe2cb9ef3230cbc4c85e42bcd56ba537f6b65a51b9c6c8552810100", case: :lower)}},
      {:NEW,          %{idx: 0, export_idx: 0, args: ["foo"]}},
      {:CALL,         %{idx: 1, method_idx: 1, args: [700, Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)]}},
      {:CALL,         %{idx: 2, method_idx: 1, args: ["bar"]}},
      {:EXEC,         %{idx: 0, export_idx: 0, method_idx: 2, args: ["mum"]}},
      {:EXECFN,       %{idx: 0, export_idx: 1, args: ["dad"]}},
      {:FUND,         %{idx: 1}},
      {:LOCK,         %{idx: 2, pubkey_hash: Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)}},
      {:LOCK,         %{idx: 3, pubkey_hash: Base.decode16!("f8be00b23c9c1c30720e862d00082121d83c4ff3", case: :lower)}},
      {:DEPLOY,       %{entry: ["index.ts"], code: %{"index.ts" => "export function helloWorld(msg: string): string { return `Hello ${msg}!` }"}}},
      {:SIGN,         %{sig: Base.decode16!("dcec284f6257490225aec9762c2b4f4683841fd76a8c67407ce58058019688f27c51945b3055e3b9c652bfddc6b2c696a9130b8159de1f9f1de31ac17693ff0f", case: :lower), pubkey: Base.decode16!("a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961", case: :lower)}},
      {:SIGNTO,       %{sig: Base.decode16!("db7134476827db2c4c096b25e3fa67e2759e295108cb676f455e354d4c984ede577daeedc097296e6b894e5f6581234be085264262a30867aff04980000ab502", case: :lower), pubkey: Base.decode16!("a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961", case: :lower)}},
    ]
  }

  test "Canonical priv and pub key and address serialisation" do
    assert {:ok, privkey} = PrivKey.from_string(@keys.privkey)
    assert {:ok, pubkey} = PubKey.from_string(@keys.pubkey)

    assert PubKey.from_privkey(privkey) |> PubKey.to_string() == @keys.pubkey
    assert PubKey.from_privkey(privkey) |> Address.from_pubkey() |> Address.to_string() == @keys.address
    assert Address.from_pubkey(pubkey) |> Address.to_string() == @keys.address
  end

  test "HD Priv and Pub key derivation" do
    seed = Mnemonic.mnemonic_to_seed(@hd_keys.seed) |> Base.decode16!(case: :lower)
    root = HDPrivKey.from_seed(seed)
    assert HDPrivKey.to_string(root) == @hd_keys.root_priv
    assert HDPubKey.from_hd_privkey(root) |> HDPubKey.to_string() == @hd_keys.root_pub

    child = HDPrivKey.derive(root, @hd_keys.child.path)
    child_pub = HDPubKey.from_hd_privkey(child)
    {:ok, pub1} = HDPubKey.get_pubkey_bytes(child_pub) |> PubKey.from_bin()
    assert HDPrivKey.to_string(child) == @hd_keys.child.priv
    assert HDPubKey.to_string(child_pub) == @hd_keys.child.pub
    assert Address.from_pubkey(pub1) |> Address.to_string() == @hd_keys.child.addr

    hard_child = HDPrivKey.derive(root, @hd_keys.hard_child.path)
    hard_child_pub = HDPubKey.from_hd_privkey(hard_child)
    {:ok, pub2} = HDPubKey.get_pubkey_bytes(hard_child_pub) |> PubKey.from_bin()
    assert HDPrivKey.to_string(hard_child) == @hd_keys.hard_child.priv
    assert HDPubKey.to_string(hard_child_pub) == @hd_keys.hard_child.pub
    assert Address.from_pubkey(pub2) |> Address.to_string() == @hd_keys.hard_child.addr
  end

  test "Kitchen sink serialisation" do
    assert {:ok, tx} = Tx.from_hex(@tx.rawtx)
    assert length(tx.instructions) == 14
    for {inst, {op, attrs}} <- Enum.zip(tx.instructions, @tx.instructions) do
      assert inst.op == op
      assert inst.attrs == attrs
    end
    assert Tx.to_hex(tx) == @tx.rawtx
  end

  # 01000ea120a0b07c4143ae6f105ea79cff5d21d2d1cd09351cf66e41c3e43bfb3bddb1a701a220df4cf424923ad248766251066fa4a408930faf94fff66c77657e79f604d3120da322675d72e2d567cbe2cb9ef3230cbc4c85e42bcd56ba537f6b65a51b9c6c8552810100b1080000000063666f6fb21c010001001902bc      74 f8be00b23c9c1c30720e862d00082121d83c4ff3b2080200010063626172b30a000000000200636d756db4080000010063646164c1020100c2160200f8be00b23c9c1c30720e862d00082121d83c4ff3c2160300f8be00b23c9c1c30720e862d00082121d83c4ff3d1608168696e6465782e7473a168696e6465782e7473784a6578706f72742066756e6374696f6e2068656c6c6f576f726c64286d73673a20737472696e67293a20737472696e67207b2072657475726e206048656c6c6f20247b6d73677d2160207de160dcec284f6257490225aec9762c2b4f4683841fd76a8c67407ce58058019688f27c51945b3055e3b9c652bfddc6b2c696a9130b8159de1f9f1de31ac17693ff0fa19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961e260db7134476827db2c4c096b25e3fa67e2759e295108cb676f455e354d4c984ede577daeedc097296e6b894e5f6581234be085264262a30867aff04980000ab502a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961
  # 01000ea120a0b07c4143ae6f105ea79cff5d21d2d1cd09351cf66e41c3e43bfb3bddb1a701a220df4cf424923ad248766251066fa4a408930faf94fff66c77657e79f604d3120da322675d72e2d567cbe2cb9ef3230cbc4c85e42bcd56ba537f6b65a51b9c6c8552810100b1080000000063666f6fb21e010001001902bc d840 54 f8be00b23c9c1c30720e862d00082121d83c4ff3b2080200010063626172b30a000000000200636d756db4080000010063646164c1020100c2160200f8be00b23c9c1c30720e862d00082121d83c4ff3c2160300f8be00b23c9c1c30720e862d00082121d83c4ff3d1608168696e6465782e7473a168696e6465782e7473784a6578706f72742066756e6374696f6e2068656c6c6f576f726c64286d73673a20737472696e67293a20737472696e67207b2072657475726e206048656c6c6f20247b6d73677d2160207de160dcec284f6257490225aec9762c2b4f4683841fd76a8c67407ce58058019688f27c51945b3055e3b9c652bfddc6b2c696a9130b8159de1f9f1de31ac17693ff0fa19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961e260db7134476827db2c4c096b25e3fa67e2759e295108cb676f455e354d4c984ede577daeedc097296e6b894e5f6581234be085264262a30867aff04980000ab502a19bb50358e253e3ded9910ce69088a327f701a4c85b7f444b6f4f6e63bbb961

end
