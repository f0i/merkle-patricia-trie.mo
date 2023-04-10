module {
    public let data = {
        source = "https://github.com/ethereum/tests/blob/develop/TrieTests/trietest.json";
        commit = "7d66cbfff1e6561d1046e45df8b7918d186b136f";
        date = "2019-01-10";
        tests = [
            (
                "emptyValues",
                {
                    input : [(Text, ?Text)] = [
                        ("do", ?"verb"),
                        ("ether", ?"wookiedoo"),
                        ("horse", ?"stallion"),
                        ("shaman", ?"horse"),
                        ("doge", ?"coin"),
                        ("ether", null),
                        ("dog", ?"puppy"),
                        ("shaman", null),
                    ];
                    root = "5991bb8c6514148a29db676a14ac506cd2cd5775ace63c30a4fe457715e9ac84";
                },
            ),
            (
                "branchingTests",
                {
                    input : [(Text, ?Text)] = [
                        ("0x04110d816c380812a427968ece99b1c963dfbce6", ?"something"),
                        ("0x095e7baea6a6c7c4c2dfeb977efac326af552d87", ?"something"),
                        ("0x0a517d755cebbf66312b30fff713666a9cb917e0", ?"something"),
                        ("0x24dd378f51adc67a50e339e8031fe9bd4aafab36", ?"something"),
                        ("0x293f982d000532a7861ab122bdc4bbfd26bf9030", ?"something"),
                        ("0x2cf5732f017b0cf1b1f13a1478e10239716bf6b5", ?"something"),
                        ("0x31c640b92c21a1f1465c91070b4b3b4d6854195f", ?"something"),
                        ("0x37f998764813b136ddf5a754f34063fd03065e36", ?"something"),
                        ("0x37fa399a749c121f8a15ce77e3d9f9bec8020d7a", ?"something"),
                        ("0x4f36659fa632310b6ec438dea4085b522a2dd077", ?"something"),
                        ("0x62c01474f089b07dae603491675dc5b5748f7049", ?"something"),
                        ("0x729af7294be595a0efd7d891c9e51f89c07950c7", ?"something"),
                        ("0x83e3e5a16d3b696a0314b30b2534804dd5e11197", ?"something"),
                        ("0x8703df2417e0d7c59d063caa9583cb10a4d20532", ?"something"),
                        ("0x8dffcd74e5b5923512916c6a64b502689cfa65e1", ?"something"),
                        ("0x95a4d7cccb5204733874fa87285a176fe1e9e240", ?"something"),
                        ("0x99b2fcba8120bedd048fe79f5262a6690ed38c39", ?"something"),
                        ("0xa4202b8b8afd5354e3e40a219bdc17f6001bf2cf", ?"something"),
                        ("0xa94f5374fce5edbc8e2a8697c15331677e6ebf0b", ?"something"),
                        ("0xa9647f4a0a14042d91dc33c0328030a7157c93ae", ?"something"),
                        ("0xaa6cffe5185732689c18f37a7f86170cb7304c2a", ?"something"),
                        ("0xaae4a2e3c51c04606dcb3723456e58f3ed214f45", ?"something"),
                        ("0xc37a43e940dfb5baf581a0b82b351d48305fc885", ?"something"),
                        ("0xd2571607e241ecf590ed94b12d87c94babe36db6", ?"something"),
                        ("0xf735071cbee190d76b704ce68384fc21e389fbe7", ?"something"),
                        ("0x04110d816c380812a427968ece99b1c963dfbce6", null),
                        ("0x095e7baea6a6c7c4c2dfeb977efac326af552d87", null),
                        ("0x0a517d755cebbf66312b30fff713666a9cb917e0", null),
                        ("0x24dd378f51adc67a50e339e8031fe9bd4aafab36", null),
                        ("0x293f982d000532a7861ab122bdc4bbfd26bf9030", null),
                        ("0x2cf5732f017b0cf1b1f13a1478e10239716bf6b5", null),
                        ("0x31c640b92c21a1f1465c91070b4b3b4d6854195f", null),
                        ("0x37f998764813b136ddf5a754f34063fd03065e36", null),
                        ("0x37fa399a749c121f8a15ce77e3d9f9bec8020d7a", null),
                        ("0x4f36659fa632310b6ec438dea4085b522a2dd077", null),
                        ("0x62c01474f089b07dae603491675dc5b5748f7049", null),
                        ("0x729af7294be595a0efd7d891c9e51f89c07950c7", null),
                        ("0x83e3e5a16d3b696a0314b30b2534804dd5e11197", null),
                        ("0x8703df2417e0d7c59d063caa9583cb10a4d20532", null),
                        ("0x8dffcd74e5b5923512916c6a64b502689cfa65e1", null),
                        ("0x95a4d7cccb5204733874fa87285a176fe1e9e240", null),
                        ("0x99b2fcba8120bedd048fe79f5262a6690ed38c39", null),
                        ("0xa4202b8b8afd5354e3e40a219bdc17f6001bf2cf", null),
                        ("0xa94f5374fce5edbc8e2a8697c15331677e6ebf0b", null),
                        ("0xa9647f4a0a14042d91dc33c0328030a7157c93ae", null),
                        ("0xaa6cffe5185732689c18f37a7f86170cb7304c2a", null),
                        ("0xaae4a2e3c51c04606dcb3723456e58f3ed214f45", null),
                        ("0xc37a43e940dfb5baf581a0b82b351d48305fc885", null),
                        ("0xd2571607e241ecf590ed94b12d87c94babe36db6", null),
                        ("0xf735071cbee190d76b704ce68384fc21e389fbe7", null),
                    ];
                    root = "56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421";
                },
            ),
            (
                "jeff",
                {
                    input : [(Text, ?Text)] = [
                        (
                            "0x0000000000000000000000000000000000000000000000000000000000000045",
                            ?"0x22b224a1420a802ab51d326e29fa98e34c4f24ea",
                        ),
                        (
                            "0x0000000000000000000000000000000000000000000000000000000000000046",
                            ?"0x67706c2076330000000000000000000000000000000000000000000000000000",
                        ),
                        (
                            "0x0000000000000000000000000000000000000000000000000000001234567890",
                            ?"0x697c7b8c961b56f675d570498424ac8de1a918f6",
                        ),
                        (
                            "0x000000000000000000000000697c7b8c961b56f675d570498424ac8de1a918f6",
                            ?"0x1234567890",
                        ),
                        (
                            "0x0000000000000000000000007ef9e639e2733cb34e4dfc576d4b23f72db776b2",
                            ?"0x4655474156000000000000000000000000000000000000000000000000000000",
                        ),
                        (
                            "0x000000000000000000000000ec4f34c97e43fbb2816cfd95e388353c7181dab1",
                            ?"0x4e616d6552656700000000000000000000000000000000000000000000000000",
                        ),
                        (
                            "0x4655474156000000000000000000000000000000000000000000000000000000",
                            ?"0x7ef9e639e2733cb34e4dfc576d4b23f72db776b2",
                        ),
                        (
                            "0x4e616d6552656700000000000000000000000000000000000000000000000000",
                            ?"0xec4f34c97e43fbb2816cfd95e388353c7181dab1",
                        ),
                        (
                            "0x0000000000000000000000000000000000000000000000000000001234567890",
                            null,
                        ),
                        (
                            "0x000000000000000000000000697c7b8c961b56f675d570498424ac8de1a918f6",
                            ?"0x6f6f6f6820736f2067726561742c207265616c6c6c793f000000000000000000",
                        ),
                        (
                            "0x6f6f6f6820736f2067726561742c207265616c6c6c793f000000000000000000",
                            ?"0x697c7b8c961b56f675d570498424ac8de1a918f6",
                        ),
                    ];
                    root = "9f6221ebb8efe7cff60a716ecb886e67dd042014be444669f0159d8e68b42100";
                },
            ),
            (
                "insert_middle_leaf",
                {
                    input : [(Text, ?Text)] = [
                        ("key1aa", ?"0123456789012345678901234567890123456789xxx"),
                        ("key1", ?"0123456789012345678901234567890123456789Very_Long"),
                        ("key2bb", ?"aval3"),
                        ("key2", ?"short"),
                        ("key3cc", ?"aval3"),
                        ("key3", ?"1234567890123456789012345678901"),
                    ];
                    root = "cb65032e2f76c48b82b5c24b3db8f670ce73982869d38cd39a624f23d62a9e89";
                },
            ),
            (
                "branch_value_update",
                {
                    input : [(Text, ?Text)] = [
                        ("abc", ?"123"),
                        ("abcd", ?"abcd"),
                        ("abc", ?"abc"),
                    ];
                    root = "7a320748f780ad9ad5b0837302075ce0eeba6c26e3d8562c67ccc0f1b273298a";
                },
            ),
        ];
    };
};
