// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Avator is ERC721 {
    string baseURI;
    address public owner;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool[4]) public whitelistUsedState; // 白单使用情况
    mapping(uint => uint) public tokenLvType; // 记录token的类型
    mapping(address => uint) userMintedAmount; // 记录mint情况
    mapping(uint => uint) tokenWear; // 记录磨损情况

    uint[] rewardTokens; // 获奖token

    uint lv1supply; // no cap
    uint lv2supply; // no cap
    uint lv3supply; // cap is 4000

    // normal price
    uint lv1price = 0.02 ether; // 从1001张开始，每售出100张，价格提升0.01eth
    uint lv2price = 0.05 ether; // 从1001张开始，每售出100张，价格提升0.01eth
    uint lv3price = 0.12 ether; // 限定<=4000张

    // wl price
    uint lv1priceWl = 0 ether;
    uint lv2priceWl = 0.03 ether;
    uint lv3priceWl = 0.09 ether;

    constructor(string memory baseURI_) ERC721("Avator", "Avator") {
        owner = msg.sender;
        baseURI = baseURI_;
        _tokenIds.increment();
    }

    // 44张mint
    function lv1Mint() external payable onlyMint(1) {
        __mint(1);
        lv1supply++;
    }

    // 112张mint
    function lv2Mint() external payable onlyMint(2) {
        __mint(2);
        lv2supply++;
    }

    // 随机一张mint
    function lv3Mint() external payable onlyMint(3) {
        require(lv3supply < 4000, "ERR_MAX_COUNT");

        __mint(3);
        lv3supply++;
    }

    function isWhiteList(address user, uint typeId) public view returns (bool) {}

    function _mintPrice(uint typeId) internal view returns (uint) {
        if (typeId == 1) {
            if (isWhiteList(msg.sender, 1)) return lv1priceWl;
            if (lv1supply > 1000) {
                return lv1price + ((lv1supply - 1000) / 100) * 0.01 ether;
            } else {
                return lv1price;
            }
        }
        if (typeId == 2) {
            if (isWhiteList(msg.sender, 2)) return lv2priceWl;
            if (lv2supply > 1000) {
                return lv2price + ((lv2supply - 1000) / 100) * 0.01 ether;
            } else {
                return lv2price;
            }
        }
        if (typeId == 3) {
            if (isWhiteList(msg.sender, 3)) return lv3priceWl;
            return lv3price;
        }

        return 1000000 ether;
    }

    function __mint(uint typeId) internal {
        uint tokenId = _tokenIds.current();
        tokenLvType[tokenId] = typeId;
        _mint(msg.sender, tokenId);

        userMintedAmount[msg.sender]++;

        _tokenIds.increment();
    }

    function setRewardTokens(uint[] memory tokens) external onlyOwner {
        rewardTokens = tokens;
    }

    function getRewardVault() external {}

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId), ".json");
    }

    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    modifier onlyMint(uint typeId) {
        require(msg.value >= _mintPrice(typeId), "ERR_ETH_NOT_ENOUGH");
        require(userMintedAmount[msg.sender] <= typeId, "ERR_CAN_NOT_MINT_MORE");
        require(whitelistUsedState[msg.sender][typeId] == false, "ERR_HAS_MINTED");
        _;
        whitelistUsedState[msg.sender][typeId] = true;
    }

    function _afterTokenTransfer(
        address,
        address,
        uint firstTokenId,
        uint
    ) internal virtual override {
        tokenWear[firstTokenId]++;
    }
}
