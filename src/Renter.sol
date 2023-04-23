// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract Renter is ERC721 {
    
    //error ListingDoesntExist();

    ERC721[] nftsOffered;
    address[] Listers;

    // Mapping from tokenId to listing
    mapping(uint256 => listing) private listings;

    struct listing
    {
        address owner;
        uint256 collateral;
        uint256 rentPrice;
        uint256 maxTime;
        bool listed;
    }

    /*
    modifier onlyListers {
        require(hasRole(LISTER_ROLE, msg.sender), "Caller is not a lister");
        _;
    }
    */

    constructor() ERC721("Test", "test") {
        
    }

    function listOne(
        uint256 _tokenId,
        uint256 _collateral,
        uint256 _rentPrice, 
        uint256 _maxTime
        ) public {

        require(_tokenId != 0, "NFT Wasn't Specified");
        require(_maxTime > 0, "Max Time Wasn't Set");

        //transfer the nft to this contract
        safeTransferFrom(msg.sender, address(this), _tokenId);

        // map the NFT data to the listing
        listing memory _listing = listing(
            msg.sender,
            _collateral,
            _rentPrice,
            _maxTime,
            true);
        listings[_tokenId] = _listing;

    }

    function removeListing(uint256 _tokenId) public {

        require(listings[_tokenId].listed == true, "Listing Doesnt Exist");
        require(listings[_tokenId].owner == msg.sender, "Not the NFT Owner");

        //send the nft back

        delete listings[_tokenId];

    }

    function rentOne(uint256 _tokenId) public {

        require(listings[_tokenId].listed == true, "Listing Doesnt Exist");

        //if not enough money sent then revert

        //if too much money sent then send back the excess

        //call _rentingProcess

        //maybe make this person a Renter

    }

    function _rentingProcess(uint256 tokenId, uint256 maxTime) private {

        //transfer nft to renter

        //transfer nft back to owner after time

    }

}