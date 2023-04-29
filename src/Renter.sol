// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract Renter is IERC721Receiver {

    address payable governance;

    // Mapping from NFT project to tokenId to listing
    mapping(IERC721 => mapping(uint256 => listing)) private listings;

    // Mapping from NFT project to tokenId to renting
    mapping(IERC721 => mapping(uint256 => renting)) private rentings;

    // Mapping from renter address to collateral
    mapping(address => uint256) private renterCollateral;

    struct listing
    {
        address owner;
        uint256 collateral;
        uint256 rentPrice;
        uint256 maxTime;
        bool listed;
    }

    struct renting
    {
        address originalOwner;
        address renter;
        uint256 collateral;
        uint256 maxTime;
        uint256 blockWhenRented;
    }

    constructor(address payable _governance) {
        
        governance = _governance;

    }

    /**
        Lists the NFT and holds it in Escrow
     */
    function listOne(
        IERC721 _nft,
        uint256 _tokenId,
        uint256 _collateral,
        uint256 _rentPrice, 
        uint256 _maxTime
        ) public {

        require(_tokenId != 0, "NFT Wasn't Specified");
        require(_maxTime > 0, "Max Time Wasn't Set");
        require(_rentPrice >= 10000, "rent price has to be at least 10000 wei");

        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // map the NFT data to the listing
        listing memory _listing = listing(
            msg.sender,
            _collateral,
            _rentPrice,
            _maxTime,
            true);
        listings[_nft][_tokenId] = _listing;

    }

    /**
        for people to remove their listings if no one rents
     */
    function removeListing(IERC721 _nft, uint256 _tokenId) public {

        require(listings[_nft][_tokenId].listed == true, "Listing Doesnt Exist");
        require(listings[_nft][_tokenId].owner == msg.sender, "Not the NFT Owner");

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        delete listings[_nft][_tokenId];

    }

    /**
        for renting a listing
     */
    function rentOne(IERC721 _nft, uint256 _tokenId) public payable {

        require(listings[_nft][_tokenId].listed == true, "Listing Doesnt Exist");
        require(msg.value >= listings[_nft][_tokenId].rentPrice, "Not enough rent money sent");
        require(renterCollateral[msg.sender] >= listings[_nft][_tokenId].collateral, "not enough collateral deposited");
        
        _rentingProcess(_nft, _tokenId);
        
        //take a 1.5% fee on the rentPrice and then send the rest to the originial owner
        //send fee to preset address in constructor
        governance.transfer((msg.value * 150) / 10000);
        payable(listings[_nft][_tokenId].owner).transfer((msg.value * 9850) / 10000);

        delete listings[_nft][_tokenId];

    }

    /**
        internal function to handle renting
     */
    function _rentingProcess(IERC721 _nft, uint256 tokenId) private {

        //transfer nft to renter
        _nft.safeTransferFrom(address(this), msg.sender, tokenId);

        renting memory _renting = renting(
            listings[_nft][tokenId].owner,
            msg.sender,
            listings[_nft][tokenId].collateral,
            listings[_nft][tokenId].maxTime,
            block.timestamp);
        rentings[_nft][tokenId] = _renting;

    }

    /**
        deposit function for collateral
     */
    function depositCollateral() public payable {

        renterCollateral[msg.sender] += msg.value;

    }

    /**
        if the renter does not return the NFT
        the orignial owner can claim the collateral

        @notice 1 day grace period
     */
    function repoCollateral(IERC721 _nft, uint256 tokenId) public {

        require(rentings[_nft][tokenId].originalOwner == msg.sender, "Not the original Owner");
       
        // Repo is open after the block time at rent + max time + 1 day grace period
        uint256 repoBlock = rentings[_nft][tokenId].blockWhenRented + (rentings[_nft][tokenId].maxTime * 86400) + 86400;
        require(block.timestamp > repoBlock, "Not enough time for repo yet");

        payable(rentings[_nft][tokenId].originalOwner).transfer(rentings[_nft][tokenId].collateral);
        
        // Remove renting to close the list-rent cycle
        delete rentings[_nft][tokenId];

    }

    /**
        handles NFT returns
        returns collateral for that nft as well

        @notice the renter cannot return the nft if it was overdue and
        the collateral was repo'd
     */
    function returnNFT(IERC721 _nft, uint256 _tokenId) public {

        // Require the renting wasnt repo'd
        // might not be optimal/safest way to check if renting was removed
        require(rentings[_nft][_tokenId].renter == msg.sender, "Collateral was repo'd, renting closed");

        //transfer from renter to orginial owner
        _nft.safeTransferFrom(msg.sender, rentings[_nft][_tokenId].originalOwner, _tokenId);

        //return collateral
        uint256 collateral = rentings[_nft][_tokenId].collateral;
        payable(msg.sender).transfer(collateral);
        renterCollateral[msg.sender] -= collateral;

        // Remove renting to close the list-rent cycle
        delete rentings[_nft][_tokenId];

    }

    /**
        for calling safeTransferFrom
     */
    function onERC721Received(address operator,
    address from, 
    uint256 tokenId, 
    bytes calldata data
    ) external returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
}