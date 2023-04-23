// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Renter.sol";
import "../src/RenterNFT.sol";

contract RenterTest is Test {

    Renter public renter;
    address lister;
    address lister2;

    function setUp() public {

        renter = new Renter();
        lister = payable(address(uint160(uint256(keccak256(abi.encodePacked("lister"))))));
        lister2 = payable(address(uint160(uint256(keccak256(abi.encodePacked("lister2"))))));

    }

    function testListOne() public {

        vm.prank(lister);
        renter.listOne(1, 2, 1, 5);

        vm.prank(lister2);
        renter.listOne(10, 20, 10, 50);

    }

    function testRemoveListing() public {

        vm.startPrank(lister);
        renter.listOne(1, 2, 1, 5);
        renter.removeListing(1);
        vm.stopPrank();

    }

    /**
        Tests when someone tries to remove someone
        else's listing.
     */
    function testFailRemoveListing() public {

        vm.prank(lister);
        renter.listOne(1, 2, 1, 5);

        vm.prank(lister2);
        renter.removeListing(1);

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

        //removes same listing twice so should revert
        vm.startPrank(lister);
        renter.listOne(1, 2, 1, 5);
        renter.removeListing(1);
        vm.expectRevert();
        renter.removeListing(1);
        vm.stopPrank();

    }

    

}