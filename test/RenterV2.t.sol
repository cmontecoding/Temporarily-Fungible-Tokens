// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {RenterV2} from "../src/RenterV2.sol";
import {RenterNFT} from "./RenterNFT.sol";

contract RenterTest is Test {
    RenterV2 public renter;
    address user1;
    uint256 user1PrivateKey;
    address user2;
    uint256 user2PrivateKey;
    uint256 governancePrivateKey;
    address payable governance;
    RenterNFT nft;

    function setUp() public {
        user1PrivateKey = 123;
        user1 = vm.addr(user1PrivateKey);
        user2PrivateKey = 456;
        user2 = vm.addr(user2PrivateKey);
        governancePrivateKey = 789;
        governance = payable(vm.addr(governancePrivateKey));

        nft = new RenterNFT();
        renter = new RenterV2(governance);

        nft.safeMint(user1, 1);

        // bytes32 messageHash = safeProxy.getTransactionHash(
//             address(safeProxy),
//             0,
//             enableModuleData,
//             Enum.Operation.Call,
//             50000,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             0
//         );

//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(
//             owner1PrivateKey,
//             messageHash
//         );

//         // Pack the ECDSA signature
//         bytes memory packedSignature = abi.encodePacked(r, s, v);

//         safeProxy.execTransaction(
//             address(safeProxy),
//             0,
//             enableModuleData,
//             Enum.Operation.Call,
//             50000,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             packedSignature
//         );
    }

    function testRent() public {

        bytes32 hash = keccak256(abi.encodePacked(
            address(renter),
            user1,
            1,
            10000,
            100000,
            0
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user1PrivateKey,
            hash
        );

        vm.prank(user2);
        renter.rentListing(
            address(nft),
            user1,
            1,
            10000,
            100000,
            0,
            r,
            s,
            v
        );

    }

}
