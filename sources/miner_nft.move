module blhn_sui_nft::miner_nft {
    use std::string::{utf8, String};
    use sui::display;
    use sui::object::{Self, UID};
    use sui::package;
    use sui::package::{from_package, Publisher};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const ENotOwner: u64 = 0;

    struct Miner has key, store {
        id: UID,
        name: String,
        image_url: String,
    }

    struct MINER_NFT has drop{}

    fun init(otw: MINER_NFT, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
        ];

        let values = vector[
            utf8(b"{name}"),
            utf8(b"ipfs://{image_url}"),
            utf8(b"The Miner NFT is a unique digital asset that is used to represent ownership of CHIRP's miner."),
            utf8(b"https://chirptoken.io/"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<Miner>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    public entry fun mint(pub: &Publisher, name: String, image_url: String, ctx: &mut TxContext) {
        assert!(from_package<Miner>(pub), ENotOwner);
        let nft = Miner {
            id: object::new(ctx),
            name: name,
            image_url: image_url,
        };
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }


    #[test_only]
    use sui::test_scenario;
    use std::string;

    #[test]
    fun mint_nft() {
        let publisher = @0xA;
        let scenario = test_scenario::begin(publisher);
        {
            init(MINER_NFT{}, test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, publisher);
        {
            let pub = test_scenario::take_from_sender<Publisher>(&scenario);
            mint(
                &pub,
                string::utf8(b"Miner NFT"),
                string::utf8(b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce"),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_to_address<Publisher>(publisher, pub);
        };
        test_scenario::next_tx(&mut scenario, publisher);
        {
            let nft = test_scenario::take_from_sender<Miner>(&scenario);
            assert!(string::index_of(&nft.name, &string::utf8(b"Miner NFT")) == 0, 1);
            assert!(string::index_of(&nft.image_url, &string::utf8(b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce")) == 0, 1);
            test_scenario::return_to_sender<Miner>(&scenario, nft);
        };
        test_scenario::end(scenario);
    }
}
