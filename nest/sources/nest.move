/// This module defines an NFT that offer perks.
module nest::nest {
    // === Imports ===

    use std::string::{Self, String};
    use sui::display;
    use sui::package::{Self};


    // === Errors ===

    /// The error code for when the argument is invalid.
    const EInvalidArgument: u64 = 1;


    // === Structs ===

    /// The Nest NFT represents user perks.
    public struct Nest has key {
        /// The unique identifier of the NFT.
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

    /// The admin capability to authorize operations.
    public struct AdminCap has key, store {
        /// The unique identifier of the capability.
        id: UID,
    }

    /// The one time witness for the Nest NFT.
    public struct NEST has drop{}


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
        let mut display = display::new_with_fields<Nest>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(AdminCap{ id: object::new(ctx) }, ctx.sender());
        transfer::public_transfer(display, ctx.sender());
    }

    /// Mints a new Nest NFT.
    public entry fun mint(
            _: &AdminCap,
            mut count: u64,
            name: String,
            image_url: String,
            description: String,
            project_url: String,
            recipient: address,
            ctx: &mut TxContext,
        ) {
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
    public entry fun transfer(_: &AdminCap, nft: Nest, recipient: address) {
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
    use nest::nest::{Self, Nest, AdminCap};
    use std::string::{Self};
    use sui::test_scenario;
    use sui::test_utils;
    const NFT_NAME: vector<u8> = b"Nest NFT";
    const NFT_IMAGE_URL: vector<u8> = b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce";
    const NFT_DESCRIPTION: vector<u8> = b"NestNFT Description";
    const NFT_PROJECT_URL: vector<u8> = b"https://nest.com";
    const PUBLISHER: address = @0xA;

    #[test]
    fun test_mint(){
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            nest::init_for_testing(scenario.ctx())
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let owner = test_scenario::take_from_sender<AdminCap>(&scenario);
            nest::mint(
                &owner,
                10,
                string::utf8(NFT_NAME),
                string::utf8(NFT_IMAGE_URL),
                string::utf8(NFT_DESCRIPTION),
                string::utf8(NFT_PROJECT_URL),
                PUBLISHER,
                scenario.ctx(),
            );
            test_scenario::return_to_address<AdminCap>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let mut nft_ids = test_scenario::ids_for_sender<Nest>(&scenario);
            test_utils::assert_eq(nft_ids.length(), 10);

            while(!nft_ids.is_empty()) {
                let nft = test_scenario::take_from_sender_by_id<Nest>(&scenario, nft_ids.pop_back());
                test_utils::assert_eq(string::index_of(&nft.name(), &string::utf8(NFT_NAME)), 0);
                test_utils::assert_eq(string::index_of(&nft.image_url(), &string::utf8(NFT_IMAGE_URL)), 0);
                test_utils::assert_eq(string::index_of(&nft.description(), &string::utf8(NFT_DESCRIPTION)), 0);
                test_utils::assert_eq(string::index_of(&nft.project_url(), &string::utf8(NFT_PROJECT_URL)), 0);
                test_scenario::return_to_sender<Nest>(&scenario, nft);
            };
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer() {
        let sender = @0xB;
        let receiver =  @0xC;
        let mut scenario = test_scenario::begin(PUBLISHER);
        {
            nest::init_for_testing(scenario.ctx())
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let owner = test_scenario::take_from_sender<AdminCap>(&scenario);
            nest::mint(
                &owner,
                1,
                string::utf8(NFT_NAME),
                string::utf8(NFT_IMAGE_URL),
                string::utf8(NFT_DESCRIPTION),
                string::utf8(NFT_PROJECT_URL),
                sender,
                scenario.ctx(),
            );

            // The AdminCap might be transferred to another account
            transfer::public_transfer(owner, sender);
        };
        test_scenario::next_tx(&mut scenario, sender);
        {
            let owner = test_scenario::take_from_sender<AdminCap>(&scenario);
            let nft = test_scenario::take_from_sender<Nest>(&scenario);
            nest::transfer(&owner, nft, receiver);
            test_scenario::return_to_sender<AdminCap>(&scenario, owner);
        };
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let nft_ids = test_scenario::ids_for_sender<Nest>(&scenario);
            test_utils::assert_eq(nft_ids.length(), 1);
        };
        test_scenario::end(scenario);
    }
}
