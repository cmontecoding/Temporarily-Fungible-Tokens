// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract Renter is ERC721, IERC721Receiver {

    ERC721[] nftsOffered;
    address[] Listers;
    IERC721 public testNFT;
    address payable governance;

    // Mapping from tokenId to listing
    mapping(uint256 => listing) private listings;

    // Mapping from tokenId to renting
    mapping(uint256 => renting) private rentings;

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

    constructor(IERC721 _address, address payable _governance) ERC721("Test", "test") {
        
        testNFT = _address;
        governance = _governance;

    }

    /**
        Lists the NFT and holds it in Escrow
     */
    function listOne(
        uint256 _tokenId,
        uint256 _collateral,
        uint256 _rentPrice, 
        uint256 _maxTime
        ) public {

        require(_tokenId != 0, "NFT Wasn't Specified");
        require(_maxTime > 0, "Max Time Wasn't Set");

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

    /**
        for people to remove their listings if no one rents
     */
    function removeListing(uint256 _tokenId) public {

        require(listings[_tokenId].listed == true, "Listing Doesnt Exist");
        require(listings[_tokenId].owner == msg.sender, "Not the NFT Owner");

        testNFT.safeTransferFrom(address(this), msg.sender, _tokenId);

        delete listings[_tokenId];

    }

    /**
        for renting a listing
     */
    function rentOne(uint256 _tokenId, uint256 amount) public payable {

        require(listings[_tokenId].listed == true, "Listing Doesnt Exist");
        require(amount >= listings[_tokenId].rentPrice, "Not enough rent money sent");
        require(renterCollateral[msg.sender] >= listings[_tokenId].collateral, "not enough collateral deposited");

        _rentingProcess(_tokenId);

        //take a 1% fee on the rentPrice and then send the rest to the originial owner
        //send fee to preset address in constructor
        governance.transfer(msg.value / 100);
        payable(listings[_tokenId].owner).transfer((msg.value * 99) / 100);

        delete listings[_tokenId];

    }

    /**
        internal function to handle renting
     */
    function _rentingProcess(uint256 tokenId) private {

        //transfer nft to renter
        safeTransferFrom(address(this), msg.sender, tokenId);

        renting memory _renting = renting(
            listings[tokenId].owner,
            msg.sender,
            listings[tokenId].collateral,
            listings[tokenId].maxTime,
            block.timestamp);
        rentings[tokenId] = _renting;

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
    function repoCollateral(uint256 tokenId) public {

        require(rentings[tokenId].originalOwner == msg.sender, "Not the original Owner");
       
        // Repo is open after the block time at rent + max time + 1 day grace period
        uint256 repoBlock = rentings[tokenId].blockWhenRented + (rentings[tokenId].maxTime * 86400) + 86400;
        require(block.timestamp > repoBlock, "Not enough time for repo yet");

        payable(rentings[tokenId].originalOwner).transfer(rentings[tokenId].collateral);
        
        // Remove renting to close the list-rent cycle
        delete rentings[tokenId];

    }

    /**
        handles NFT returns
        returns collateral for that nft as well

        @notice the renter cannot return the nft if it was overdue and
        the collateral was repo'd
     */
    function returnNFT(address payable user, uint256 _tokenId) public {

        // Require the renting wasnt repo'd
        // might not be optimal way to check if renting was removed
        require(rentings[_tokenId].renter == msg.sender, "Collateral was repo'd, renting closed");

        //transfer from renter to this contract
        safeTransferFrom(msg.sender, address(this), _tokenId);

        //return collateral
        uint256 collateral = listings[_tokenId].collateral;
        user.transfer(collateral);
        renterCollateral[msg.sender] -= collateral;

        // Remove renting to close the list-rent cycle
        delete rentings[_tokenId];

    }

    //public function to add nfts offered

    //probably need a getter function too to get the nfts token id

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