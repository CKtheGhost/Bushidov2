// contracts/contracts/BushidoNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BushidoNFT is ERC721, ERC721Enumerable, Ownable {
    
    // Constants
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant CLANS_COUNT = 8;
    uint256 public constant TOKENS_PER_CLAN = 200;
    
    // State
    uint256 private _tokenIdCounter;
    mapping(uint256 => uint256) public tokenClan;
    mapping(uint256 => uint256) public tokenRarity;
    mapping(address => uint256) public mintedPerWallet;
    mapping(uint256 => uint256) public votingPower;
    
    bool public mintActive = false;
    string private _baseTokenURI;
    
    // Events
    event MintActivated();
    event TokenMinted(address indexed to, uint256 tokenId, uint256 clan, uint256 rarity);
    
    constructor() ERC721("Bushido", "BUSHIDO") {}
    
    function activateMint() external onlyOwner {
        require(!mintActive, "Already active");
        mintActive = true;
        emit MintActivated();
    }
    
    function mint(uint256 quantity) external payable {
        require(mintActive, "Mint not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(mintedPerWallet[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds wallet limit");
        require(_tokenIdCounter + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter++;
            uint256 tokenId = _tokenIdCounter;
            
            // Assign clan sequentially (200 per clan)
            uint256 clan = ((tokenId - 1) / TOKENS_PER_CLAN) + 1;
            uint256 rarity = _generateRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            votingPower[tokenId] = _calculateVotingPower(rarity);
            
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(msg.sender, tokenId, clan, rarity);
        }
        
        mintedPerWallet[msg.sender] += quantity;
    }
    
    function _generateRarity(uint256 tokenId) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, tokenId)));
        uint256 normalized = rand % 100;
        
        if (normalized < 1) return 5;      // Legendary (1%)
        if (normalized < 5) return 4;      // Epic (4%)  
        if (normalized < 15) return 3;     // Rare (10%)
        if (normalized < 35) return 2;     // Uncommon (20%)
        return 1;                          // Common (65%)
    }
    
    function _calculateVotingPower(uint256 rarity) private pure returns (uint256) {
        return rarity ** 2; // 1, 4, 9, 16, 25
    }
    
    function getVotingPower(address holder) external view returns (uint256) {
        uint256 totalPower = 0;
        uint256 balance = balanceOf(holder);
        
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(holder, i);
            totalPower += votingPower[tokenId];
        }
        
        return totalPower;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        payable(owner()).transfer(balance);
    }
    
    // Required overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}