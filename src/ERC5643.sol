// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC5643.sol";

error RenewalTooShort();
error RenewalTooLong();
error InsufficientPayment();
error SubscriptionNotRenewable();
error InvalidTokenId();
error CallerNotOwnerNorApproved();

contract ERC5643 is ERC721, IERC5643 {
    mapping(uint256 => uint64) private _expirations;
    mapping(uint256 => bool) private _restrictedTokenIds;

    uint64 private minimumRenewalDuration;
    uint64 private maximumRenewalDuration;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function renewSubscription(uint256 tokenId, uint64 duration)
        external
        payable
        override
        notRestrictedTokens(tokenId)
    {
        address owner = ownerOf(tokenId);
        require(
            _isAuthorized(owner, msg.sender, tokenId),
            "Caller is not owner nor approved"
        );

        require(
            duration >= minimumRenewalDuration,
            "Renewal duration too short"
        );
        require(
            maximumRenewalDuration == 0 || duration <= maximumRenewalDuration,
            "Renewal duration too long"
        );

        require(
            msg.value >= _getRenewalPrice(tokenId, duration),
            "Insufficient payment"
        );

        _extendSubscription(tokenId, duration);
    }

    function cancelSubscription(uint256 tokenId)
        public
        payable
        override
        virtual
    {
        address owner = ownerOf(tokenId);
        require(
            _isAuthorized(owner, msg.sender, tokenId),
            "Caller is not owner nor approved"
        );

        delete _expirations[tokenId];

        emit SubscriptionUpdate(tokenId, 0);
    }

    function _restrictTokens(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        _restrictedTokenIds[tokenId] = true;
        cancelSubscription(tokenId);
    }

    function expiresAt(uint256 tokenId)
        external
        view
        override
        returns (uint64)
    {
        require(_exists(tokenId), "Token does not exist");
        return _expirations[tokenId];
    }

    function isRenewable(uint256 tokenId)
        external
        view
        override
        notRestrictedTokens(tokenId)
        returns (bool)
    {
        require(_exists(tokenId), "Token does not exist");
        return _isRenewable(tokenId);
    }

    function _isRenewable(uint256 tokenId)
        internal
        view
        override
        notRestrictedTokens(tokenId)
        returns (bool)
    {
        return true;
    }

    function _setMinimumRenewalDuration(uint64 duration) internal onlyOwner {
        minimumRenewalDuration = duration;
    }

    function _setMaximumRenewalDuration(uint64 duration) internal onlyOwner {
        maximumRenewalDuration = duration;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC5643)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _exists(uint256 tokenId) public view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    modifier notRestrictedTokens(uint256 tokenId) {
        require(!_restrictedTokenIds[tokenId], "Token is restricted");
        _;
    }
}