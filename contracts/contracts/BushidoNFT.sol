// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBushidoNFT.sol";
import "./libraries/VotingPower.sol";

contract BushidoNFT is ERC721Enumerable, Ownable, IBushidoNFT {
    using Counters for Counters.Counter;
    using VotingPower for uint256;
    
    // Constants
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant CLANS_COUNT = 8;
    
    // State
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public tokenClan;
    mapping(uint256 => uint256) public tokenRarity;
    mapping(address => uint256) public mintedPerWallet;
    
    bool public mintActive;
    string private _baseTokenURI;
    
    // Events
    event MintActivated(uint256 timestamp);
    event TokenMinted(address indexed to, uint256 tokenId, uint256 clan, uint256 rarity);
    event VoteCast(uint256 indexed episodeId, uint256 indexed tokenId, string choice);
    
    constructor() ERC721("Bushido", "BUSHIDO") Ownable(msg.sender) {}
    
    function activateMint() external onlyOwner {
        require(!mintActive, "Already active");
        mintActive = true;
        emit MintActivated(block.timestamp);
    }
    
    function mint(uint256 quantity) external payable {
        require(mintActive, "Mint not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(mintedPerWallet[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient ETH");
        
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            // Determine clan and rarity
            uint256 clan = (tokenId - 1) / 200;
            uint256 rarity = _determineRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(msg.sender, tokenId, clan, rarity);
        }
        
        mintedPerWallet[msg.sender] += quantity;
    }
    
    function getVotingPower(uint256 tokenId) public view returns (uint256) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenRarity[tokenId].calculateVotingPower();
    }
    
    function _determineRarity(uint256 tokenId) private pure returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId))) % 1000;
        
        if (rand < 25) return 4; // Legendary - 2.5%
        if (rand < 100) return 3; // Epic - 7.5%
        if (rand < 250) return 2; // Rare - 15%
        if (rand < 500) return 1; // Uncommon - 25%
        return 0; // Common - 50%
    }
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
