// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract Renter is ERC721, IERC721Receiver {

    ERC721[] nftsOffered;
    address[] Listers;
    IERC721 public testNFT;

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

    constructor(IERC721 _address) ERC721("Test", "test") {
        
        testNFT = _address;

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
        testNFT.safeTransferFrom(msg.sender, address(this), _tokenId);

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
        testNFT.safeTransferFrom(address(this), msg.sender, _tokenId);

        delete listings[_tokenId];

    }

    function rentOne(uint256 _tokenId, uint256 amount) public payable {

        require(listings[_tokenId].listed == true, "Listing Doesnt Exist");

        //if not enough money sent then revert
        require(amount >= listings[_tokenId].rentPrice, "Not enough rent money sent");

        //if too much money sent then send back the excess
        if (amount > listings[_tokenId].rentPrice) {

        }

        //call _rentingProcess

        //map this person as a Renter to the NFT

        //take a 1% fee on the rentPrice and then send the rest to the originial owner

    }

    function depositCollateral() public payable {

        //mapping for collateral

    }

    function withdrawalCollateral(uint256 amount) public {

        //check if msg.sender has collateral

        //change the collateral mapping

        //return money

    }

    function _rentingProcess(uint256 tokenId, uint256 maxTime) private {

        //transfer nft to renter

        //transfer nft back to owner after time

    }

    
    function onERC721Received(address operator,
    address from, 
    uint256 tokenId, 
    bytes calldata data
    ) external returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
}