/// This module defines an NFT for representing miners in the Sui ecosystem.
module blhn_sui_nft::skyward {
    // === Imports ===

    use std::string::{Self, String};
    use sui::display;
    use sui::object::{Self, UID};
    use sui::package::{Self, Publisher};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};


    // === Errors ===

    /// The error code for when the sender is not owner of NFT contract.
    const ENotOwner: u64 = 0;


    // === Structs ===

    /// The Skyward NFT represents ownership of a miner in the Sui ecosystem.
    struct Skyward has key, store {
        /// The unique identifier of the skyward NFT.
        id: UID,
        /// The name of the Skyward NFT.
        name: String,
        /// The URL of the image representing the Skyward NFT.
        image_url: String,
    }

    /// The one time witness for the Skyward NFT.
    struct SKYWARD has drop{}


  // === Admin Functions ===

    fun init(otw: SKYWARD, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"project_url"),
        ];
        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"ipfs://{image_url}"),
            string::utf8(b"Skyward NFT symbolizes CHIRP miner ownership."),
            string::utf8(b"https://chirptoken.io/"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<Skyward>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    /// Mints a new Skyward NFT.
    public entry fun mint(pub: &Publisher, name: String, image_url: String, ctx: &mut TxContext) {
        assert!(package::from_package<Skyward>(pub), ENotOwner);
        assert!(package::from_module<Skyward>(pub), ENotOwner);
        let nft = Skyward {
            id: object::new(ctx),
            name: name,
            image_url: image_url,
        };
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    /// Burns a Skyward NFT.
    public entry fun burn(nft: Skyward) {
        let Skyward { id, name: _, image_url: _ } = nft;
        object::delete(id);
    }

    #[test_only]
    use sui::test_scenario;
    #[test_only]
    use sui::test_utils;
    #[test_only]
    const NFT_NAME: vector<u8> = b"Skyward NFT";
    #[test_only]
    const NFT_IMAGE_URL: vector<u8> = b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce";
    #[test_only]
    const PUBLISHER: address = @0xA;

    #[test]
    fun test_mint(){
        let scenario = test_scenario::begin(PUBLISHER);
        {
            init(SKYWARD{}, test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            mint(&owner, string::utf8(NFT_NAME), string::utf8(NFT_IMAGE_URL), test_scenario::ctx(&mut scenario));
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let nft = test_scenario::take_from_sender<Skyward>(&scenario);
            test_utils::assert_eq(string::index_of(&nft.name, &string::utf8(NFT_NAME)), 0);
            test_utils::assert_eq(string::index_of(&nft.image_url, &string::utf8(NFT_IMAGE_URL)), 0);
            test_scenario::return_to_sender<Skyward>(&scenario, nft);
        };
        test_scenario::end(scenario);
    }
}
