// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

contract RandomDeck {
    struct Card {
        uint256 number;
        bytes32 salt;
        bytes32 hash;
    }

    Card[52] public cards;
    bytes32[52] public deck;

    function setCards() public {
        uint256 i = 0;

        cards[i++] = Card({
            number: 24,
            salt: 0x6626a98234203e9b1bdf5dc9ec990069d70ee55a60a6a317975b8a08e70a82e3,
            hash: 0x8ec4ea5595fe6fc5ca8afd258a45589c9e4977063393f0efe9992dfefb493a6e
        });

        cards[i++] = Card({
            number: 48,
            salt: 0x2d479fa697a05095c6b273e6037a0fcfedaa1c8025aff3294a9f70e91dc99183,
            hash: 0xeedd9f629bcf288c9524a73a9b3bce2f6270d3ab8a1cf79da8f1e73d0bef84f1
        });

        cards[i++] = Card({
            number: 16,
            salt: 0x34dc2d08bcdf0a35fc0ffb0bfeaf33f58166109bd04c13b7fbf476d5a9aec3dc,
            hash: 0xad5216334ff28422fb866f6fa84096269c80a17ec1a914bdd84c3d54ae96d352
        });

        cards[i++] = Card({
            number: 1,
            salt: 0xddf0ce5b037e45978475def080b7528c59bad70887b2777ec8c5e85be2ecf189,
            hash: 0x7e4f0120c8acc6be690252746dc9cd323295eaffefd428cb37e21bdd3c94b729
        });

        cards[i++] = Card({
            number: 8,
            salt: 0x3f6268f21d42d049e3358cf0de8f395f8c9c992f695961b0b96f348e5fae0d25,
            hash: 0x92c04e937b463283e543fbfface038a9f41bdb9c285fcd10f93d50b5c1b18a40
        });

        cards[i++] = Card({
            number: 0,
            salt: 0xddfbbff3c4c43035f1970a00091ed5ba8c500bd54cfa6644a34cafce21e0cd85,
            hash: 0xb636e719976522f247e4f070c601ed0176868b3517c7f49c93b2fbb2da61eabd
        });

        cards[i++] = Card({
            number: 34,
            salt: 0xd737d275ee9c916fa9d1c720f992ee0f81c87bcf6abf02ae6bc3783cabfea320,
            hash: 0x9986e49e3051355fa1318843ab82eb63ff19f591a3997c2b92d74bc2f78632d4
        });

        cards[i++] = Card({
            number: 29,
            salt: 0xc6dee8c6956c232d258f61e00731e2da7fa8327163d688bb311b2402addfb7bf,
            hash: 0x19135d3fa655361f115a3de4cc0b1e466cd80fd18a513f41d0d439b17910eb17
        });

        cards[i++] = Card({
            number: 36,
            salt: 0x9f0aa4dd19b0c691b580e15bc5262a27dbd9a77ccfd700da3c95a4422daa19b9,
            hash: 0x886e4b543635fc318f7988423dba1c61fc352ef169b20fdb1a9bc47e2cd2fb54
        });

        cards[i++] = Card({
            number: 30,
            salt: 0x574cfa8f540b6f2eec37fd6e771452c139038d6a9d2f5f6ac9a9c621d1bf8a14,
            hash: 0x00eed5de78e3b1b2ad297635a29592d5dc6d05939c67497d9c035654df6c8527
        });

        cards[i++] = Card({
            number: 41,
            salt: 0x884d038ddd2c139bfaaadeccf00da6178b7efcc2bd7b7797ceea77ab327c28dc,
            hash: 0x0b8a991dcf915b24d04e219e1be70a4e3643dffd86efe77a70bcb54021e491c1
        });

        cards[i++] = Card({
            number: 51,
            salt: 0x5c3f972932abd3fa293c714b70e31e36925f5f060140508ec29f923cc5a14b37,
            hash: 0xf4f27a65a3362e1f60574fb602a782fc7ed73149bec81379fb3c5bea0be01e90
        });

        cards[i++] = Card({
            number: 19,
            salt: 0xad1aa57b7768567ca9ee79d037cad27ed35237bd5e947d7d5342183b600786d0,
            hash: 0xc4bb1c7e6e85b69884542537a107accf7f87968348702ccd17789e3464e61c00
        });

        cards[i++] = Card({
            number: 39,
            salt: 0xa890499488f2a52de463736a69fcab5ca8b149a9b2ea055c6e0e28bf5756722c,
            hash: 0x5d9a930a7d144f11d4e484e08daecdefc3ec6d053965d4a10e4cc3b34aef968e
        });

        cards[i++] = Card({
            number: 5,
            salt: 0x477c35e0889342556d2a35bd239769bca2f0983ef0b3cdd92e45eff130ead4fe,
            hash: 0x954a142b842aeca92b53afa6ab8ed00824e522065a140e5b2b52ffbf6da5a58d
        });

        cards[i++] = Card({
            number: 44,
            salt: 0x24d2b93c9ddf58cab31293d4034a51a329ab586b63cd03ba476d144d09115ae3,
            hash: 0xa43b2aa17a898fd0f67e8e12c862747f3d46460e353d41fefac309955b5e8687
        });

        cards[i++] = Card({
            number: 13,
            salt: 0x1dbac0283d57257f4d345b3bffff67d88b33de9628beebe40abeb6264933f7b3,
            hash: 0x51198292f470a730ab0026033479e5478fba138a22e8825eed881fd18df79c0c
        });

        cards[i++] = Card({
            number: 20,
            salt: 0x8cad5c182da3ada54aadf433f622b480719deff9d8863808ec6062c2abb4cf2a,
            hash: 0x090c4c03c22052293ca9bd2f3e7b42e7148dc77d0aaff6f7e803a5aa3f76c3e6
        });

        cards[i++] = Card({
            number: 38,
            salt: 0x7e2105c9a12374bbe07db43847606dfb9167b3bb3ee4303cbb5dd29021964b9b,
            hash: 0xf2449b7479ab5f20db94580e2e0ba8dd7a90ab7c3a3c834d741dae051ac24269
        });

        cards[i++] = Card({
            number: 17,
            salt: 0x9e0c1dca5f908d82d5e18eeea87e2180d3421cac7edccdc395b99f7807177cd7,
            hash: 0xdf0de45a4cb1248b68aecd3278c3c0a36117c7cb5d9eb8469c05f9503c99cc43
        });

        cards[i++] = Card({
            number: 42,
            salt: 0x5f22a10d25aac3d143140e2ada865323bee16af5eeddbd62e938ad73ea59bb97,
            hash: 0x7c4a65264dca11824059e61b2e7fc538684e83cadc3427f139fa37089ec8b2a5
        });

        cards[i++] = Card({
            number: 15,
            salt: 0x7b30c092590cffa031c70f9662af2782b84e19c3a0262d7fea9e481ed3dbdf91,
            hash: 0x3922b3fabc1b01cbaed2b40b64d4e092a8c846bfcea28a0cc5694647e4dada74
        });

        cards[i++] = Card({
            number: 11,
            salt: 0x4c0af0827dca0a6318a84b0565d0f20f9fe10517a50a549af3ce67eb8f1af118,
            hash: 0x4599bc63f039e478ad5548f3d30e1d4f78b432dd51a55eec81e87a5d8619b5c3
        });

        cards[i++] = Card({
            number: 40,
            salt: 0x75cdcff6076b9bb6530e5db14ec13145cb647136a195dd48458112fe74011b0a,
            hash: 0xe15d351c2df396be70048c4f5b1e2d9c303a386dccf00df6165ce683d9a8dac7
        });

        cards[i++] = Card({
            number: 43,
            salt: 0x69d5c86d270012228aa7c1d7638f1f4922c072a5e58275c37c8eff674e47eea3,
            hash: 0xaaf33cd36af96d4634c0b2eac1dbe1e579601e1c63cabb288745117701271a95
        });

        cards[i++] = Card({
            number: 33,
            salt: 0xc10bf7f8eb2d396dbbebafc2ba2791bec58bdbfcda55b03094fd52497f3f8862,
            hash: 0x11694a4cce348987710f9d2369ad0ad601e559b88565910b83bcb30c606a3fb9
        });

        cards[i++] = Card({
            number: 27,
            salt: 0xe657caa828ee1890162a6a82863c2d010fa4e534ae4c8d331b73021c6ae1cdb1,
            hash: 0xd93e4f11b0418aae08711c2087db0e6ece146fa5061e5dfce723ab1453bb5857
        });

        cards[i++] = Card({
            number: 21,
            salt: 0xd52befba3fc8884023100c3498daede661648f06035990ced6b21ec689c23d4f,
            hash: 0xbdc230dd33fa4872a4d6f20d58e297880a2af0719779938bf37af8ccd1ffb9f0
        });

        cards[i++] = Card({
            number: 2,
            salt: 0xcb3e5a4774db106c6a9ffe340ed7d71b3beb2139adec944fa2316346ac4e9dc9,
            hash: 0xfd4fabc82be0a24e09cce1c8e7a57bbc4f49fc0e569d643933ad42e62847f4aa
        });

        cards[i++] = Card({
            number: 32,
            salt: 0x9a31282802524bb656b1f243a0e6a73e347a1ea5189d4f782151e2e06ea36c76,
            hash: 0xea626643113e407d7689e1967638ae72102f2043e78b0d4f27cfed54283be808
        });

        cards[i++] = Card({
            number: 28,
            salt: 0x932d7e0aac6d3126912fe0409f1f0f627f340e4d7bee4df03446b3fc5269e87e,
            hash: 0x8497da06e4451f93325b3947588dc233d4ccb43aa11272f2ec161722e4712e43
        });

        cards[i++] = Card({
            number: 22,
            salt: 0x3143aaa2265730ea87ccd4ef2d2a2b22621c12c91d075fbc29d1146ee9ed4115,
            hash: 0xd93d0519cc64d536d8f7687f684958d3c16093b33cb81e9b4ca49f7505c5d00f
        });

        cards[i++] = Card({
            number: 35,
            salt: 0x9de2c62a01c8670c7fe53b08caa30e81c4cbd37ee92b561bf081c0672f94b712,
            hash: 0x3eae3c6c1beb133c91a5eec5397a7b5a43198856ed11f9ab521efd32c336c2a2
        });

        cards[i++] = Card({
            number: 31,
            salt: 0xfb3804a68ae5a42904c2c8c31023b713718e6290e6a18f600c1023c7ce742053,
            hash: 0x0b3f0ba8932f864bf7fe496570f010fb358545b69fd4a35f382276565255c9c1
        });

        cards[i++] = Card({
            number: 9,
            salt: 0xde9f57fd23f9c81376c3b352e1842215807c8e8cd6ba0802fd0e50508bed649e,
            hash: 0xd99653bf1811929788ae5638a3be62359391ea55cd229dd0379fe656683f1429
        });

        cards[i++] = Card({
            number: 10,
            salt: 0xc0fe44db42a9ef7be831ae73053b55dea85c997b713757f1ce8aae8f1128118a,
            hash: 0x7a98138a233bacac54c923c476e2377d8462c4af7c5870568e1a81a39222a0ed
        });

        cards[i++] = Card({
            number: 7,
            salt: 0xa128ef5eeb6696be7e86999c7fad5cc60f6f4338044a353c43c89e3345cdb34b,
            hash: 0x8c2a77944238f0d7a78d20b573b1c020b7a00ae8603a952af0dc099ad8e7dad3
        });

        cards[i++] = Card({
            number: 25,
            salt: 0xa0a08680966d9deaaaa8d5df033b12f05aa34a21fd78bb725ec5d5ec40f7ee00,
            hash: 0x01efa5ae3a7e247600ba31abe5938b9a91d5092ab5e656a5d50680d9c4edcb9c
        });

        cards[i++] = Card({
            number: 49,
            salt: 0x6a3812e48edd5aa93c157aed0b54fb0fc76602c980868f85136dc4f704b009d2,
            hash: 0xcc5d5363b869f756fc27975842ad4f0af07bd654fe10866a739ec4be2b445fb2
        });

        cards[i++] = Card({
            number: 3,
            salt: 0x837813e9911513d1e8de47896ff632ed6ab228b6449b0dad5b5c5f576babf8a8,
            hash: 0xb205568a01156dce5cc05ef4282f7a541a9ce412f49c404c1d8dbe7bdd96c70a
        });

        cards[i++] = Card({
            number: 45,
            salt: 0x8fe537f2779666ff94f527822ff34c34e619c7097fc143325ded991e9f5ad55e,
            hash: 0xabe8320e1ae7836f023cc2059c75a15bc2a5e44abb7001b9f5b3dacb442cf9c3
        });

        cards[i++] = Card({
            number: 12,
            salt: 0x3b2f58ffdbabe3310ae87c7c54abbfd0ce5beb8ee83c898f00d15f5959e10392,
            hash: 0xd05a925b3047619687a2448df3b4487774021e28a0f871b8115b39b95f3ea6b9
        });

        cards[i++] = Card({
            number: 50,
            salt: 0x29b2846437e56f8131b88e54985cdc9d0b70a743441bce290ebb0d26b969bd17,
            hash: 0xee55120428f63b8d756ebb48c112e5b32ee3763dcf1f37061fc0d361ea29d214
        });

        cards[i++] = Card({
            number: 23,
            salt: 0xb56e5c830cd34be811e731a69146231d962ff44dc7227a0cd168926d79279e9b,
            hash: 0xeb39465b73991c96f48246a93903c82e24382c3edf7f8a1779d43bb1fa676484
        });

        cards[i++] = Card({
            number: 18,
            salt: 0x6b9cfc957a8de74b70ba6f94c9a6cdfba854c9bb97669211a3e94271fe26dfde,
            hash: 0x400e98586e5a9a4a2c064bc7aaab89497214056937d97ad6b3b76493dbc02802
        });

        cards[i++] = Card({
            number: 47,
            salt: 0xe90633e13a9a95421e745958828e4d4169665eb0ec342f3df7b06299bea8f1a0,
            hash: 0xc0c6d42228def10cba3ea85d9699d709d8d55cde6df2b5b3795b891d8cd8ed21
        });

        cards[i++] = Card({
            number: 4,
            salt: 0x2165330cd0493e5c4ac6b4a35fefb817ebc6036f2cd512320dcf1212b838e8e0,
            hash: 0x685508424490f07f235d0bb142a02afba5dd120670799eabb35b0e81b75e7306
        });

        cards[i++] = Card({
            number: 26,
            salt: 0x78036308c62cc0baacb277d4900af30edfd2f361fe7123fb3a537c867bc2158b,
            hash: 0x0518ee7947cb8b7c266bac6ed218b1fe52193cc044434efd9459a0c892be4bb2
        });

        cards[i++] = Card({
            number: 37,
            salt: 0x807a702be0391893891d4c594103da537ea7bce55953ed596e4d1344c53824a8,
            hash: 0x208634c508cc01a96651afd3737ec7621159f725538b0b1db15169da85158025
        });

        cards[i++] = Card({
            number: 46,
            salt: 0x74ba4cc0c6c4a22cbf201fdc81a621dc2aad328d2f759a3f750acf49a0ca15d4,
            hash: 0x3bc4eadd55d3a4ed333888794988245b2f04172e6ce43797010cff22b4973950
        });

        cards[i++] = Card({
            number: 6,
            salt: 0x39f3a5662ea8d8e313deebc73cba8578c275c7a267bd95af31ed428f543aef33,
            hash: 0x45c3c5e9b021b42da951d4e6611e3d449aab4fd974cfec82e4788c2165642437
        });

        cards[i++] = Card({
            number: 14,
            salt: 0x42bdb586f9297deea7627e8fcfe3c558a3665a5d311e95fd18b18deb84845727,
            hash: 0x2af1c3774d0d2c7fd4376e0f58f3334840f1a0bf5ef8cb23af7792d8e0e3eb26
        });

        for (uint256 j = 0; j < 52; ++j) {
            deck[j] = cards[j].hash;
        }
    }
}
