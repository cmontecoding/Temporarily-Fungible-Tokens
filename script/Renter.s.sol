// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Renter.sol";

contract MyScript is Script {

    //public address
    address public governance = 0x3C704e28C8EfCC7aCa262031818001895595081D;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        console.log(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        Renter renter = new Renter(payable(governance));

        vm.stopBroadcast();
    }
}