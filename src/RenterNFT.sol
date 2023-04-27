// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract RenterNFT is ERC721, ERC721Burnable, Ownable {

    constructor() ERC721("RenterNFT", "MTK") {

        transferOwnership(msg.sender);

    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    

}