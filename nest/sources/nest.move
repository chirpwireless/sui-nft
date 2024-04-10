/// This module defines an NFT that offer perks.
module nest::nest {
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

    /// The Nest NFT represents user perks.
    struct Nest has key {
        /// The unique identifier of NFT.
        id: UID,
        /// The name of the NFT.
        name: String,
        /// The description of the NFT.
        description: String,
        /// The URL of the image representing the NFT.
        image_url: String,
        /// The URL of the project associated with the NFT.
        project_url: String,
    }

    /// The transfer capability to authorize the transfer of a NFT.
    struct TransferCap<phantom T> has key, store {
        /// The unique identifier of the capability.
        id: UID,
    }

    /// The one time witness for the Nest NFT.
    struct NEST has drop{}


  // === Admin Functions ===

    fun init(otw: NEST, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"project_url"),
        ];
        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"ipfs://{image_url}"),
            string::utf8(b"{description}"),
            string::utf8(b"{project_url}"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<Nest>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(TransferCap<NEST>{ id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    /// Mints a new Nest NFT.
    public entry fun mint(
            pub: &Publisher,
            count: u64,
            name: String,
            image_url: String,
            description:String,
            project_url: String,
            recipient: address,
            ctx: &mut TxContext,
        ) {
        assert!(package::from_package<Nest>(pub), ENotOwner);
        assert!(package::from_module<Nest>(pub), ENotOwner);
        assert!(count > 0, EInvalidArgument);
        while(count > 0) {
            let nft = Nest {
                id: object::new(ctx),
                name: name,
                description: description,
                project_url: project_url,
                image_url: image_url,
            };
            transfer::transfer(nft, recipient);
            count = count - 1;
        }
    }

    /// Transfers a Nest NFT to a new owner.
    public entry fun transfer(_: &TransferCap<NEST>, nft: Nest, recipient: address) {
        transfer::transfer(nft, recipient);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(NEST{}, ctx)
    }

    #[test_only]
    public fun name(nft: &Nest): String {
        nft.name
    }

    #[test_only]
    public fun image_url(nft: &Nest): String {
        nft.image_url
    }

    #[test_only]
    public fun description(nft: &Nest): String {
        nft.description
    }

    #[test_only]
    public fun project_url(nft: &Nest): String {
        nft.project_url
    }
}

#[test_only]
module nest::nest_tests {
    use nest::nest::{Self, NEST, Nest, TransferCap};
    use std::string::{Self};
    use std::vector;
    use sui::package::{Publisher};
    use sui::test_scenario;
    use sui::test_utils;
    use sui::transfer;
    const NFT_NAME: vector<u8> = b"Nest NFT";
    const NFT_IMAGE_URL: vector<u8> = b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce";
    const NFT_DESCRIPTION: vector<u8> = b"NestNFT Description";
    const NFT_PROJECT_URL: vector<u8> = b"https://nest.com";
    const PUBLISHER: address = @0xA;

    #[test]
    fun test_mint(){
        let scenario = test_scenario::begin(PUBLISHER);
        {
            nest::init_for_testing(test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            nest::mint(
                &owner,
                10,
                string::utf8(NFT_NAME),
                string::utf8(NFT_IMAGE_URL),
                string::utf8(NFT_DESCRIPTION),
                string::utf8(NFT_PROJECT_URL),
                PUBLISHER,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let nft_ids = test_scenario::ids_for_sender<Nest>(&scenario);
            test_utils::assert_eq(vector::length(&nft_ids), 10);

            while(!vector::is_empty(&nft_ids)) {
                let nft = test_scenario::take_from_sender_by_id<Nest>(&scenario, vector::pop_back(&mut nft_ids));
                test_utils::assert_eq(string::index_of(&nest::name(&nft), &string::utf8(NFT_NAME)), 0);
                test_utils::assert_eq(string::index_of(&nest::image_url(&nft), &string::utf8(NFT_IMAGE_URL)), 0);
                test_utils::assert_eq(string::index_of(&nest::description(&nft), &string::utf8(NFT_DESCRIPTION)), 0);
                test_utils::assert_eq(string::index_of(&nest::project_url(&nft), &string::utf8(NFT_PROJECT_URL)), 0);
                test_scenario::return_to_sender<Nest>(&scenario, nft);
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
            nest::init_for_testing(test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            // The TransferCap might be transferred to another account
            let cap = test_scenario::take_from_sender<TransferCap<NEST>>(&scenario);
            transfer::public_transfer(cap, sender);
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            nest::mint(
                &owner,
                1,
                string::utf8(NFT_NAME),
                string::utf8(NFT_IMAGE_URL),
                string::utf8(NFT_DESCRIPTION),
                string::utf8(NFT_PROJECT_URL),
                sender,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, sender);
        {
            let cap = test_scenario::take_from_sender<TransferCap<NEST>>(&scenario);
            let nft = test_scenario::take_from_sender<Nest>(&scenario);
            nest::transfer(&cap, nft, receiver);
            test_scenario::return_to_sender<TransferCap<NEST>>(&scenario, cap);
        };
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let nft_ids = test_scenario::ids_for_sender<Nest>(&scenario);
            test_utils::assert_eq(vector::length(&nft_ids), 1);
        };
        test_scenario::end(scenario);
    }

}
