/// This module defines an NFT for representing miners in the Sui ecosystem.
module rare::rare {
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

    /// The error code for when the argument is invalid.
    const EInvalidArgument: u64 = 1;


    // === Structs ===

    /// The Rare NFT represents user perks.
    struct Rare has key {
        /// The unique identifier of NFT.
        id: UID,
        /// The name of the NFT.
        name: String,
        /// The URL of the image representing the NFT.
        image_url: String,
    }

    /// The transfer capability to authorize the transfer of a NFT.
    struct TransferCap has key, store {
        /// The unique identifier of the capability.
        id: UID,
    }

    /// The one time witness for the Rare NFT.
    struct RARE has drop{}


  // === Admin Functions ===

    fun init(otw: RARE, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"project_url"),
        ];
        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"ipfs://{image_url}"),
            string::utf8(b"Rare NFT"),
            string::utf8(b"https://chirptoken.io/"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<Rare>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(TransferCap{ id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    /// Mints a new Rare NFT.
    public entry fun mint(pub: &Publisher, count: u64, name: String, image_url: String, recipient: address, ctx: &mut TxContext) {
        assert!(package::from_package<Rare>(pub), ENotOwner);
        assert!(package::from_module<Rare>(pub), ENotOwner);
        assert!(count > 0, EInvalidArgument);
        while(count > 0) {
            let nft = Rare {
                id: object::new(ctx),
                name: name,
                image_url: image_url,
            };
            transfer::transfer(nft, recipient);
            count = count - 1;
        }
    }

    /// Transfers a Rare NFT to a new owner.
    public entry fun transfer(_: &TransferCap, nft: Rare, recipient: address) {
        transfer::transfer(nft, recipient);
    }

    #[test_only]
    use sui::test_scenario;
    #[test_only]
    use sui::test_utils;
    #[test_only]
    use std::vector;
    #[test_only]
    const NFT_NAME: vector<u8> = b"Rare NFT";
    #[test_only]
    const NFT_IMAGE_URL: vector<u8> = b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce";
    #[test_only]
    const PUBLISHER: address = @0xA;

    #[test]
    fun test_mint(){
        let scenario = test_scenario::begin(PUBLISHER);
        {
            init(RARE{}, test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            mint(&owner, 10, string::utf8(NFT_NAME), string::utf8(NFT_IMAGE_URL), PUBLISHER, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let nft_ids = test_scenario::ids_for_sender<Rare>(&scenario);
            test_utils::assert_eq(vector::length(&nft_ids), 10);

            while(!vector::is_empty(&nft_ids)) {
                let nft = test_scenario::take_from_sender_by_id<Rare>(&scenario, vector::pop_back(&mut nft_ids));
                test_utils::assert_eq(string::index_of(&nft.name, &string::utf8(NFT_NAME)), 0);
                test_utils::assert_eq(string::index_of(&nft.image_url, &string::utf8(NFT_IMAGE_URL)), 0);
                test_scenario::return_to_sender<Rare>(&scenario, nft);
            };
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer() {
        let sender = @0xB;
        let receiver =  @0xC;
        let scenario = test_scenario::begin(PUBLISHER);
        {
            init(RARE{}, test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            // The TransferCap might be transferred to another account
            let cap = test_scenario::take_from_sender<TransferCap>(&scenario);
            transfer::public_transfer(cap, sender);
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            mint(&owner, 1, string::utf8(NFT_NAME), string::utf8(NFT_IMAGE_URL), sender, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, sender);
        {
            let cap = test_scenario::take_from_sender<TransferCap>(&scenario);
            let nft = test_scenario::take_from_sender<Rare>(&scenario);
            transfer(&cap, nft, receiver);
            test_scenario::return_to_sender<TransferCap>(&scenario, cap);
        };
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let nft_ids = test_scenario::ids_for_sender<Rare>(&scenario);
            test_utils::assert_eq(vector::length(&nft_ids), 1);
        };
        test_scenario::end(scenario);
    }
}
