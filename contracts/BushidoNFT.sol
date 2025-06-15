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

/**
 * @title BushidoNFT
 * @notice Interactive NFT collection with episodic voting mechanics
 * @dev Implements ERC721 with whitelist, public mint, and voting system
 */
contract BushidoNFT is ERC721Enumerable, Ownable, ReentrancyGuard, IBushidoNFT {
    using Counters for Counters.Counter;
    using VotingPower for uint256;
    
    // ═══════════════════════════════════════════════════════════════════
    // Constants
    // ═══════════════════════════════════════════════════════════════════
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0.03 ether;
    uint256 public constant CLANS_COUNT = 8;
    uint256 public constant WARRIORS_PER_CLAN = 200;
    
    // ═══════════════════════════════════════════════════════════════════
    // State Variables
    // ═══════════════════════════════════════════════════════════════════
    Counters.Counter private _tokenIdCounter;
    
    // Mint phases
    enum MintPhase { CLOSED, WHITELIST, PUBLIC }
    MintPhase public currentPhase = MintPhase.CLOSED;
    
    // Whitelist verification
    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistMinted;
    uint256 public constant MAX_WHITELIST_MINT = 2;
    
    // Token metadata
    mapping(uint256 => uint256) public tokenClan;
    mapping(uint256 => uint256) public tokenRarity;
    mapping(address => uint256) public publicMinted;
    
    // Voting system
    mapping(uint256 => mapping(uint256 => bool)) public hasVoted; // tokenId => episodeId => voted
    mapping(uint256 => mapping(string => uint256)) public episodeVotes; // episodeId => choice => votes
    mapping(uint256 => bool) public episodeActive;
    uint256 public currentEpisode;
    
    string private _baseTokenURI;
    
    // ═══════════════════════════════════════════════════════════════════
    // Events
    // ═══════════════════════════════════════════════════════════════════
    event PhaseChanged(MintPhase newPhase);
    event MerkleRootUpdated(bytes32 newRoot);
    event TokenMinted(address indexed to, uint256 tokenId, uint256 clan, uint256 rarity);
    event VoteCast(uint256 indexed episodeId, uint256 indexed tokenId, string choice, uint256 votingPower);
    event EpisodeCreated(uint256 indexed episodeId);
    event EpisodeEnded(uint256 indexed episodeId);
    
    // ═══════════════════════════════════════════════════════════════════
    // Constructor
    // ═══════════════════════════════════════════════════════════════════
    constructor() ERC721("Bushido", "BUSHIDO") Ownable(msg.sender) {}
    
    // ═══════════════════════════════════════════════════════════════════
    // Mint Functions
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @notice Set the current mint phase
     * @param _phase New mint phase
     */
    function setMintPhase(MintPhase _phase) external onlyOwner {
        currentPhase = _phase;
        emit PhaseChanged(_phase);
    }
    
    /**
     * @notice Update merkle root for whitelist verification
     * @param _merkleRoot New merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }
    
    /**
     * @notice Whitelist mint for KOLs and early supporters
     * @param quantity Number of tokens to mint
     * @param merkleProof Proof for whitelist verification
     */
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
        
        // Verify merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");
        
        _mintTokens(msg.sender, quantity);
        whitelistMinted[msg.sender] += quantity;
    }
    
    /**
     * @notice Public mint function
     * @param quantity Number of tokens to mint
     */
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
    
    /**
     * @notice Internal function to mint tokens
     * @param to Recipient address
     * @param quantity Number of tokens to mint
     */
    function _mintTokens(address to, uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            // Determine clan and rarity
            uint256 clan = ((tokenId - 1) / WARRIORS_PER_CLAN);
            uint256 rarity = _determineRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            
            _safeMint(to, tokenId);
            emit TokenMinted(to, tokenId, clan, rarity);
        }
    }
    
    /**
     * @notice Reserve tokens for team and partnerships
     * @param to Recipient address
     * @param quantity Number of tokens to reserve
     */
    function reserve(address to, uint256 quantity) external onlyOwner {
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        _mintTokens(to, quantity);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Voting System
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @notice Create a new voting episode
     * @param episodeId Unique identifier for the episode
     */
    function createEpisode(uint256 episodeId) external onlyOwner {
        require(!episodeActive[episodeId], "Episode already exists");
        episodeActive[episodeId] = true;
        currentEpisode = episodeId;
        emit EpisodeCreated(episodeId);
    }
    
    /**
     * @notice End a voting episode
     * @param episodeId Episode to end
     */
    function endEpisode(uint256 episodeId) external onlyOwner {
        require(episodeActive[episodeId], "Episode not active");
        episodeActive[episodeId] = false;
        emit EpisodeEnded(episodeId);
    }
    
    /**
     * @notice Cast vote for an episode
     * @param tokenId Token used for voting
     * @param episodeId Episode to vote on
     * @param choice Voting choice
     */
    function vote(uint256 tokenId, uint256 episodeId, string memory choice) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(episodeActive[episodeId], "Episode not active");
        require(!hasVoted[tokenId][episodeId], "Already voted");
        
        uint256 votingPower = getVotingPower(tokenId);
        hasVoted[tokenId][episodeId] = true;
        episodeVotes[episodeId][choice] += votingPower;
        
        emit VoteCast(episodeId, tokenId, choice, votingPower);
    }
    
    /**
     * @notice Get voting power for a token
     * @param tokenId Token to check
     * @return Voting power based on rarity
     */
    function getVotingPower(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenRarity[tokenId].calculateVotingPower();
    }
    
    /**
     * @notice Get vote count for an episode choice
     * @param episodeId Episode identifier
     * @param choice Voting choice
     * @return Total votes for the choice
     */
    function getVoteCount(uint256 episodeId, string memory choice) external view returns (uint256) {
        return episodeVotes[episodeId][choice];
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Metadata Functions
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @notice Set base URI for token metadata
     * @param baseURI New base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    /**
     * @notice Get token URI
     * @param tokenId Token to get URI for
     * @return Token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Utility Functions
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @notice Determine rarity based on probability
     * @param tokenId Token identifier for randomness
     * @return Rarity tier (0-4)
     */
    function _determineRarity(uint256 tokenId) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, tokenId))) % 1000;
        
        if (rand < 25) return 4;  // Legendary - 2.5%
        if (rand < 100) return 3; // Epic - 7.5%
        if (rand < 250) return 2; // Rare - 15%
        if (rand < 500) return 1; // Uncommon - 25%
        return 0; // Common - 50%
    }
    
    /**
     * @notice Check if token exists
     * @param tokenId Token to check
     * @return exists Whether token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    /**
     * @notice Get total minted tokens
     * @return Total supply minted
     */
    function totalMinted() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    /**
     * @notice Withdraw contract balance
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @notice Emergency pause function
     */
    function emergencyPause() external onlyOwner {
        currentPhase = MintPhase.CLOSED;
        emit PhaseChanged(MintPhase.CLOSED);
    }
}