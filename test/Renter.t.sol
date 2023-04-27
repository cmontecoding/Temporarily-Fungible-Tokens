// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Renter.sol";
import "../src/RenterNFT.sol";

contract RenterTest is Test {

    Renter public renter;
    address lister;
    address lister2;
    RenterNFT nft;

    function setUp() public {

        lister = payable(address(uint160(uint256(keccak256(abi.encodePacked("lister"))))));
        lister2 = payable(address(uint160(uint256(keccak256(abi.encodePacked("lister2"))))));

        nft = new RenterNFT();
        renter = new Renter(nft);

    }

    function testListOne() public {

        nft.safeMint(lister, 10);
        vm.startPrank(lister);
        nft.approve(address(renter), 10);
        renter.listOne(10, 2, 1, 5);

        assertTrue(nft.ownerOf(10) == address(renter));

    }

    function testRemoveListing() public {

        //set up
        nft.safeMint(lister, 10);
        vm.startPrank(lister);
        nft.approve(address(renter), 10);
        renter.listOne(10, 2, 1, 5);
        assertTrue(nft.ownerOf(10) == address(renter));

        renter.removeListing(10);
        assertTrue(nft.ownerOf(10) == address(lister));

    }

    /**
        Tests when someone tries to remove someone
        else's listing.
     */
    function testFailRemoveOthersListing() public {

        //set up
        nft.safeMint(lister, 10);
        vm.startPrank(lister);
        nft.approve(address(renter), 10);
        renter.listOne(10, 2, 1, 5);
        vm.stopPrank();
        assertTrue(nft.ownerOf(10) == address(renter));

        vm.prank(lister2);
        renter.removeListing(10);

    }

    /**
        test when there is no listing for
        inputed tokenId
     */
     function testRemoveEmptyListing() public {

        //removes non-existent listing
        vm.prank(lister);
        vm.expectRevert();
        renter.removeListing(7);

     }

     /**
        tests removing a listing that was
        already taken down
      */
    function testDoubleRemoveListing() public {

        //set up
        nft.safeMint(lister, 10);
        vm.startPrank(lister);
        nft.approve(address(renter), 10);
        renter.listOne(10, 2, 1, 5);
        assertTrue(nft.ownerOf(10) == address(renter));

        renter.removeListing(10);
        assertTrue(nft.ownerOf(10) == address(lister));

        vm.expectRevert();
        renter.removeListing(10);

    }

    

}