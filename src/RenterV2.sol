// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {EIP712} from "openzeppelin-contracts/utils/cryptography/EIP712.sol";

contract RenterV2 is IERC721Receiver, EIP712 {
    address payable governance;

    // // Mapping from NFT project to tokenId to listing
    // mapping(IERC721 => mapping(uint256 => listing)) private listings;

    // // Mapping from NFT project to tokenId to renting
    // mapping(IERC721 => mapping(uint256 => renting)) private rentings;

    // // Mapping from renter address to collateral
    // mapping(address => uint256) private renterCollateral;

    // struct listing {
    //     address owner;
    //     uint256 collateral;
    //     uint256 rentPrice;
    //     uint256 maxTime;
    //     bool listed;
    // }

    // struct renting {
    //     address originalOwner;
    //     address renter;
    //     uint256 collateral;
    //     uint256 maxTime;
    //     uint256 blockWhenRented;
    // }

    mapping(bytes32 => Status) public status;
    mapping(address => mapping(uint256 => bool)) public nonces;

    enum Status {
        UNSET,
        FILLED,
        CANCELLED
    }

    constructor(address payable _governance) EIP712("RenterV2", "1") {
        governance = _governance;
    }

    // /**
    //     Lists the NFT and holds it in Escrow
    //  */
    // function listOne(
    //     IERC721 _nft,
    //     uint256 _tokenId,
    //     uint256 _collateral,
    //     uint256 _rentPrice,
    //     uint256 _maxTime
    // ) public {
    //     require(_tokenId != 0, "NFT Wasn't Specified");
    //     require(_maxTime > 0, "Max Time Wasn't Set");
    //     require(_rentPrice >= 10000, "rent price has to be at least 10000 wei");

    //     _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

    //     // map the NFT data to the listing
    //     listing memory _listing = listing(
    //         msg.sender,
    //         _collateral,
    //         _rentPrice,
    //         _maxTime,
    //         true
    //     );
    //     listings[_nft][_tokenId] = _listing;
    // }

    // /**
    //     for people to remove their listings if no one rents
    //  */
    // function removeListing(IERC721 _nft, uint256 _tokenId) public {
    //     require(
    //         listings[_nft][_tokenId].listed == true,
    //         "Listing Doesnt Exist"
    //     );
    //     require(
    //         listings[_nft][_tokenId].owner == msg.sender,
    //         "Not the NFT Owner"
    //     );

    //     _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

    //     delete listings[_nft][_tokenId];
    // }

    /// @dev for renting an NFT listing
    function rentListing(
        address token,
        address seller,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint256 nonce,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public payable {
        require(msg.value == price, "INSUFFICIENT_PAYMENT");
        require(!nonces[seller][nonce], "NONCE_ALREADY_USED");
        require(block.timestamp <= deadline, "DEADLINE_PASSED");
        // todo
        // require(
        //     renterCollateral[msg.sender] >= listings[_nft][_tokenId].collateral,
        //     "not enough collateral deposited"
        // );

        // _rentOne(_nft, _tokenId);
        bytes32 hash = deriveHash(
            token,
            seller,
            tokenId,
            price,
            deadline,
            nonce
        );
        require(status[hash] == Status.UNSET, "FILLED_OR_CANCELLED");

        address recovered = ecrecover(hash, v, r, s); //todo s is malleable so fix that somehow
        require(recovered != address(0), "RECOVERY_FAILED");
        require(seller == recovered, "INVALID_SIGNATURE");

        nonces[seller][nonce] = true;
        status[hash] = Status.FILLED;

        /// @dev transfer the NFT to the renter
        IERC721(token).safeTransferFrom(seller, msg.sender, tokenId);

        /// @dev take a 1.5% fee on the rent price for governance
        /// and then send the rest to the originial owner
        uint256 fee = (price * 150) / 10000; //todo double check if this could overflow, also make this a changeable variable eventually
        governance.transfer(fee);
        payable(seller).transfer(price - fee);
    }

    function deriveHash(
        address token,
        address seller,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint256 nonce
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "RentListing(address token,address seller,uint256 tokenId,uint256 price,uint256 deadline,uint256 nonce)"
                ),
                token,
                seller,
                tokenId,
                price,
                deadline,
                nonce
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        return hash;
    }

    // /// @dev internal function for the renting process
    // function _rentListing(IERC721 _nft, uint256 tokenId) private {
    //     _nft.safeTransferFrom(address(this), msg.sender, tokenId);

    //     renting memory _renting = renting(
    //         listings[_nft][tokenId].owner,
    //         msg.sender,
    //         listings[_nft][tokenId].collateral,
    //         listings[_nft][tokenId].maxTime,
    //         block.timestamp
    //     );
    //     rentings[_nft][tokenId] = _renting;
    // }

    // /**
    //     deposit function for collateral
    //  */
    // function depositCollateral() public payable {
    //     renterCollateral[msg.sender] += msg.value;
    // }

    // /**
    //     if the renter does not return the NFT
    //     the orignial owner can claim the collateral

    //     @notice 1 day grace period
    //  */
    // function repoCollateral(IERC721 _nft, uint256 tokenId) public {
    //     require(
    //         rentings[_nft][tokenId].originalOwner == msg.sender,
    //         "Not the original Owner"
    //     );

    //     // Repo is open after the block time at rent + max time + 1 day grace period
    //     uint256 repoBlock = rentings[_nft][tokenId].blockWhenRented +
    //         (rentings[_nft][tokenId].maxTime * 86400) +
    //         86400;
    //     require(block.timestamp > repoBlock, "Not enough time for repo yet");

    //     payable(rentings[_nft][tokenId].originalOwner).transfer(
    //         rentings[_nft][tokenId].collateral
    //     );

    //     // Remove renting to close the list-rent cycle
    //     delete rentings[_nft][tokenId];
    // }

    // /**
    //     handles NFT returns
    //     returns collateral for that nft as well

    //     @notice the renter cannot return the nft if it was overdue and
    //     the collateral was repo'd
    //  */
    // function returnNFT(IERC721 _nft, uint256 _tokenId) public {
    //     // Require the renting wasnt repo'd
    //     // might not be optimal/safest way to check if renting was removed
    //     require(
    //         rentings[_nft][_tokenId].renter == msg.sender,
    //         "Collateral was repo'd, renting closed"
    //     );

    //     //transfer from renter to orginial owner
    //     _nft.safeTransferFrom(
    //         msg.sender,
    //         rentings[_nft][_tokenId].originalOwner,
    //         _tokenId
    //     );

    //     //return collateral
    //     uint256 collateral = rentings[_nft][_tokenId].collateral;
    //     payable(msg.sender).transfer(collateral);
    //     renterCollateral[msg.sender] -= collateral;

    //     // Remove renting to close the list-rent cycle
    //     delete rentings[_nft][_tokenId];
    // }

    /**
        for calling safeTransferFrom
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
