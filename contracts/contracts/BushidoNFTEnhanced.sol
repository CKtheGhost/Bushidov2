// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBushidoNFT.sol";
import "./libraries/VotingPower.sol";

contract BushidoNFT is ERC721Enumerable, Ownable, ReentrancyGuard, IBushidoNFT {
    using Counters for Counters.Counter;
    using VotingPower for uint256;
    
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0.03 ether;
    uint256 public constant CLANS_COUNT = 8;
    uint256 public constant WARRIORS_PER_CLAN = 200;
    
    Counters.Counter private _tokenIdCounter;
    
    enum MintPhase { CLOSED, WHITELIST, PUBLIC }
    MintPhase public currentPhase = MintPhase.CLOSED;
    
    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistMinted;
    uint256 public constant MAX_WHITELIST_MINT = 2;
    
    mapping(uint256 => uint256) public tokenClan;
    mapping(uint256 => uint256) public tokenRarity;
    mapping(address => uint256) public publicMinted;
    
    mapping(uint256 => mapping(uint256 => bool)) public hasVoted;
    mapping(uint256 => mapping(string => uint256)) public episodeVotes;
    mapping(uint256 => bool) public episodeActive;
    uint256 public currentEpisode;
    
    string private _baseTokenURI;
    
    event PhaseChanged(MintPhase newPhase);
    event MerkleRootUpdated(bytes32 newRoot);
    event TokenMinted(address indexed to, uint256 tokenId, uint256 clan, uint256 rarity);
    event VoteCast(uint256 indexed episodeId, uint256 indexed tokenId, string choice, uint256 votingPower);
    event EpisodeCreated(uint256 indexed episodeId);
    event EpisodeEnded(uint256 indexed episodeId);
    
    constructor() ERC721("Bushido", "BUSHIDO") Ownable(msg.sender) {}
    
    function setMintPhase(MintPhase _phase) external onlyOwner {
        currentPhase = _phase;
        emit PhaseChanged(_phase);
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }
    
    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) 
        external 
        payable 
        nonReentrant 
    {
        require(currentPhase == MintPhase.WHITELIST, "Whitelist mint not active");
        require(quantity > 0 && quantity <= MAX_WHITELIST_MINT, "Invalid quantity");
        require(whitelistMinted[msg.sender] + quantity <= MAX_WHITELIST_MINT, "Exceeds whitelist limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");
        
        _mintTokens(msg.sender, quantity);
        whitelistMinted[msg.sender] += quantity;
    }
    
    function mint(uint256 quantity) 
        external 
        payable 
        nonReentrant 
    {
        require(currentPhase == MintPhase.PUBLIC, "Public mint not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(publicMinted[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds wallet limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        _mintTokens(msg.sender, quantity);
        publicMinted[msg.sender] += quantity;
    }
    
    function _mintTokens(address to, uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            uint256 clan = ((tokenId - 1) / WARRIORS_PER_CLAN);
            uint256 rarity = _determineRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            
            _safeMint(to, tokenId);
            emit TokenMinted(to, tokenId, clan, rarity);
        }
    }
    
    function vote(uint256 tokenId, uint256 episodeId, string memory choice) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(episodeActive[episodeId], "Episode not active");
        require(!hasVoted[tokenId][episodeId], "Already voted");
        
        uint256 votingPower = getVotingPower(tokenId);
        hasVoted[tokenId][episodeId] = true;
        episodeVotes[episodeId][choice] += votingPower;
        
        emit VoteCast(episodeId, tokenId, choice, votingPower);
    }
    
    function getVotingPower(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenRarity[tokenId].calculateVotingPower();
    }
    
    function _determineRarity(uint256 tokenId) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, tokenId))) % 1000;
        
        if (rand < 25) return 4;
        if (rand < 100) return 3;
        if (rand < 250) return 2;
        if (rand < 500) return 1;
        return 0;
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    function totalMinted() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
