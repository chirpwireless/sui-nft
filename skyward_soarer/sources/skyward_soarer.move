/// This module defines an NFT that users can exchange for a real miner.
module skyward_soarer::skyward_soarer {
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

    /// The SkywardSoarer NFT can be exchanged for a real miner.
    struct SkywardSoarer has key, store {
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
        /// The link associated with NFT.
        link: String,
    }

    /// The one time witness for the NFT.
    struct SKYWARD_SOARER has drop{}


  // === Admin Functions ===

    fun init(otw: SKYWARD_SOARER, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"project_url"),
            string::utf8(b"link"),
        ];
        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"ipfs://{image_url}"),
            string::utf8(b"{description}"),
            string::utf8(b"{project_url}"),
            string::utf8(b"{link}"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<SkywardSoarer>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    /// Mints a new SkywardSoarer NFT.
    public entry fun mint(
            pub: &Publisher,
            count: u64,
            name: String,
            image_url: String,
            description: String,
            project_url: String,
            link: String,
            recipient: address,
            ctx: &mut TxContext,
        ) {
        assert!(package::from_package<SkywardSoarer>(pub), ENotOwner);
        assert!(package::from_module<SkywardSoarer>(pub), ENotOwner);
        assert!(count > 0, EInvalidArgument);
        while(count > 0) {
            let nft = SkywardSoarer {
                id: object::new(ctx),
                name: name,
                description: description,
                project_url: project_url,
                image_url: image_url,
                link: link,
            };
            transfer::public_transfer(nft, recipient);
            count = count - 1;
        }
    }

    /// Burns a SkywardSoarer NFT.
    public entry fun burn(nft: SkywardSoarer) {
        let SkywardSoarer { id, name: _, description: _, project_url: _, image_url: _, link: _ } = nft;
        object::delete(id);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(SKYWARD_SOARER{}, ctx)
    }

    #[test_only]
    public fun name(nft: &SkywardSoarer): String {
        nft.name
    }

    #[test_only]
    public fun image_url(nft: &SkywardSoarer): String {
        nft.image_url
    }

    #[test_only]
    public fun description(nft: &SkywardSoarer): String {
        nft.description
    }

    #[test_only]
    public fun project_url(nft: &SkywardSoarer): String {
        nft.project_url
    }

    #[test_only]
    public fun link(nft: &SkywardSoarer): String {
        nft.link
    }

}

#[test_only]
module skyward_soarer::skyward_soarer_tests {
    use sui::test_scenario;
    use sui::test_utils;
    use std::vector;
    use std::string::{Self};
    use sui::package::{Publisher};
    use skyward_soarer::skyward_soarer::{Self, SkywardSoarer};
    const NFT_NAME: vector<u8> = b"SkywardSoarer NFT";
    const NFT_IMAGE_URL: vector<u8> = b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce";
    const NFT_DESCRIPTION: vector<u8> = b"SkywardSoarer NFT Description";
    const NFT_PROJECT_URL: vector<u8> = b"https://skyward.soarer.com";
    const NFT_LINK: vector<u8> = b"https://skyward.soarer.com/link";
    const PUBLISHER: address = @0xA;

    #[test]
    fun test_mint(){
        let scenario = test_scenario::begin(PUBLISHER);
        {
            skyward_soarer::init_for_testing(test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            skyward_soarer::mint(
                &owner,
                10,
                string::utf8(NFT_NAME),
                string::utf8(NFT_IMAGE_URL),
                string::utf8(NFT_DESCRIPTION),
                string::utf8(NFT_PROJECT_URL),
                string::utf8(NFT_LINK),
                PUBLISHER,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let nft_ids = test_scenario::ids_for_sender<SkywardSoarer>(&scenario);
            test_utils::assert_eq(vector::length(&nft_ids), 10);

            while(!vector::is_empty(&nft_ids)) {
                let nft = test_scenario::take_from_sender_by_id<SkywardSoarer>(&scenario, vector::pop_back(&mut nft_ids));
                test_utils::assert_eq(string::index_of(&skyward_soarer::name(&nft), &string::utf8(NFT_NAME)), 0);
                test_utils::assert_eq(string::index_of(&skyward_soarer::image_url(&nft), &string::utf8(NFT_IMAGE_URL)), 0);
                test_utils::assert_eq(string::index_of(&skyward_soarer::description(&nft), &string::utf8(NFT_DESCRIPTION)), 0);
                test_utils::assert_eq(string::index_of(&skyward_soarer::project_url(&nft), &string::utf8(NFT_PROJECT_URL)), 0);
                test_utils::assert_eq(string::index_of(&skyward_soarer::link(&nft), &string::utf8(NFT_LINK)), 0);
                test_scenario::return_to_sender<SkywardSoarer>(&scenario, nft);
            };
        };
        test_scenario::end(scenario);
    }
}
