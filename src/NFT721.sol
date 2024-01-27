// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC5643.sol";

contract SubscriptionNFT is Ownable, ERC721, ERC5643 {
    enum Subscriptions {
        Mobile,
        Web
    }

    mapping(Subscriptions => uint256) public subscriptionPricesPerDay;
    mapping(uint256 => Subscriptions) public tokenSubscriptions;

    uint64 private constant ONE_DAY = 1 days;
    uint64 private constant THIRTY_DAYS = 30 days;
    uint64 private constant NINETY_DAYS = 90 days;
    uint64 private constant ONE_EIGHTY_DAYS = 180 days;
    uint64 private constant THREE_SIXTY_FIVE_DAYS = 365 days;

    constructor(
        address initialOwner,
        string memory name_,
        string memory symbol_,
        uint256 _mobilePrice,
        uint256 _webPrice
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        subscriptionPricesPerDay[Subscriptions.Mobile] = _mobilePrice;
        subscriptionPricesPerDay[Subscriptions.Web] = _webPrice;
    }

    function safeMint(
        address to,
        uint64 duration,
        Subscriptions subscriptionType
    ) external onlyOwner {
        require(
            _isValidDuration(duration) &&
                _isValidSubscriptionInterval(duration),
            "Invalid duration or subscription interval"
        );

        uint256 tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
        _extendSubscription(tokenId, duration);
        tokenSubscriptions[tokenId] = subscriptionType;
    }

    function _getRenewalPrice(
        uint256 tokenId,
        uint64 duration
    ) internal view override returns (uint256) {
        require(_requireOwned(tokenId), "Token does not exist");

        Subscriptions subscriptionType = tokenSubscriptions[tokenId];
        return duration * subscriptionPricesPerDay[subscriptionType];
    }

    function restrictTokens(uint256 tokenId) external onlyOwner {
        _restrictTokens(tokenId);
    }

    function _cancelSubscription(uint256 tokenId) external payable virtual {
        cancelSubscription(tokenId);
    }

    function setMinimumRenewalDuration(uint64 duration) external onlyOwner {
        _setMinimumRenewalDuration(duration);
    }

    function setMaximumRenewalDuration(uint64 duration) external onlyOwner {
        _setMaximumRenewalDuration(duration);
    }

    function extendSubscription(uint256 tokenId, uint64 duration) external {
        _extendSubscription(tokenId, duration);
    }

    function _isValidDuration(uint64 duration) private view returns (bool) {
        return
            duration >= minimumRenewalDuration &&
            duration <= maximumRenewalDuration;
    }

    function _isValidSubscriptionInterval(uint64 duration)
        private
        pure
        returns (bool)
    {
        return
            duration == THIRTY_DAYS ||
            duration == NINETY_DAYS ||
            duration == ONE_EIGHTY_DAYS ||
            duration == THREE_SIXTY_FIVE_DAYS;
    }
}