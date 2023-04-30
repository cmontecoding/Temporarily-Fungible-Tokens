// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Renter.sol";
import "./RenterNFT.sol";

contract RenterTest is Test {
    Renter public renter;
    address user;
    address user2;
    address payable governance;
    RenterNFT nft;

    function setUp() public {
        user = payable(
            address(uint160(uint256(keccak256(abi.encodePacked("user")))))
        );
        user2 = payable(
            address(uint160(uint256(keccak256(abi.encodePacked("user2")))))
        );
        governance = payable(
            address(uint160(uint256(keccak256(abi.encodePacked("governance")))))
        );

        nft = new RenterNFT();
        renter = new Renter(governance);
    }

    function testListOne() public {
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 2, 1 ether, 5);

        assertTrue(nft.ownerOf(10) == address(renter));
    }

    function testRemoveListing() public {
        //set up
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 2, 1 ether, 5);
        assertTrue(nft.ownerOf(10) == address(renter));

        renter.removeListing(nft, 10);
        assertTrue(nft.ownerOf(10) == address(user));
    }

    /**
        Tests when someone tries to remove someone
        else's listing. Should fail.
     */
    function testFailRemoveOthersListing() public {
        //set up
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 2, 1, 5);
        vm.stopPrank();
        assertTrue(nft.ownerOf(10) == address(renter));

        vm.prank(user2);
        renter.removeListing(nft, 10);
    }

    /**
        test when there is no listing for
        inputed tokenId

        Should revert
     */
    function testRemoveEmptyListing() public {
        //removes non-existent listing
        vm.prank(user);
        vm.expectRevert();
        renter.removeListing(nft, 7);
    }

    /**
        tests removing a listing that was
        already taken down

        Should revert
      */
    function testDoubleRemoveListing() public {
        //set up
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 2, 1 ether, 5);
        assertTrue(nft.ownerOf(10) == address(renter));

        renter.removeListing(nft, 10);
        assertTrue(nft.ownerOf(10) == address(user));

        vm.expectRevert();
        renter.removeListing(nft, 10);
    }

    /**
        test depositing collateral
     */
    function testDepositCollateral() public {
        vm.deal(user, 5 ether);
        vm.prank(user);
        renter.depositCollateral{value: 5 ether}();

        assertTrue(address(renter).balance == 5 ether);
    }

    /**
        test rent one function
     */
    function testRentOne() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();

        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();

        assertTrue(nft.ownerOf(10) == user2);
        console.log("this is the governance balance: ", governance.balance);
        console.log("this is the user balance: ", user.balance);
        assertEq(governance.balance, 150);
        assertEq(user.balance, 9850);
    }

    /**
        test rent one for when listing doesnt exist
     */
    function testFailRentOneNoListing() public {
        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();
    }

    /**
        test rent one for when not enough rent money is sent
    */
    function testFailRentOneNotEnoughRent() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();

        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 9999}(nft, 10);
        vm.stopPrank();
    }

    /**
        test rent one for when not enough collateral is in the contract
    */
    function testFailRentOneNotEnoughCollateral() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();

        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 10000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();
    }

    /**
        test repo collateral
    */
    function testRepoCollateral() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();
        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();

        vm.warp(block.timestamp + (86400 * 5) + 86401);
        vm.prank(user);
        renter.repoCollateral(nft, 10);

        assertTrue(nft.ownerOf(10) == user2);
        assertEq(user.balance, 20000 + 9850);
    }

    /**
        test repo collateral for if someone but the owner tries to repo
    */
    function testFailRepoCollateralNotOwner() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();
        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();
        vm.warp(block.timestamp + (86400 * 5) + 86401);

        vm.prank(user2);
        renter.repoCollateral(nft, 10);
    }

    /**
        test repo collateral for if not enough time has passed yet
    */
    function testFailRepoCollateralNotEnoughTime() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();
        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();

        vm.warp(block.timestamp + (86400 * 5) + 86399);
        vm.prank(user);
        renter.repoCollateral(nft, 10);
    }

    /**
        test repo collateral for if the NFT was already returned
    */
    function testFailRepoCollateralNftAlreadyReturned() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();
        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();

        //return NFT
        vm.startPrank(user2);
        nft.approve(address(renter), 10);
        renter.returnNFT(nft, 10);
        vm.stopPrank();

        vm.warp(block.timestamp + (86400 * 5) + 86401);
        vm.prank(user);
        renter.repoCollateral(nft, 10);
    }

    /**
        test return NFT
    */
    function testReturnNFT() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();
        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();

        vm.startPrank(user2);
        nft.approve(address(renter), 10);
        renter.returnNFT(nft, 10);
        vm.stopPrank();

        assertTrue(nft.ownerOf(10) == user);
        assertEq(user.balance, 9850);
        assertEq(user2.balance, 20000);
    }

    /**
        test return NFT if the renting's collateral was already repo'd
     */
    function testFailReturnNftAlreadyRepod() public {
        //setup
        nft.safeMint(user, 10);
        vm.startPrank(user);
        nft.approve(address(renter), 10);
        renter.listOne(nft, 10, 20000, 10000, 5);
        vm.stopPrank();
        vm.deal(user2, 30000);
        vm.startPrank(user2);
        renter.depositCollateral{value: 20000}();
        renter.rentOne{value: 10000}(nft, 10);
        vm.stopPrank();

        //repo NFT
        vm.warp(block.timestamp + (86400 * 5) + 86401);
        vm.prank(user);
        renter.repoCollateral(nft, 10);

        vm.startPrank(user2);
        nft.approve(address(renter), 10);
        renter.returnNFT(nft, 10);
        vm.stopPrank();
    }
}
