import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";

describe("BushidoNFT", function () {
  async function deployBushidoFixture() {
    const [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    const BushidoNFT = await ethers.getContractFactory("BushidoNFT");
    const bushido = await BushidoNFT.deploy();
    
    return { bushido, owner, addr1, addr2, addrs };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { bushido, owner } = await loadFixture(deployBushidoFixture);
      expect(await bushido.owner()).to.equal(owner.address);
    });

    it("Should have correct constants", async function () {
      const { bushido } = await loadFixture(deployBushidoFixture);
      expect(await bushido.MAX_SUPPLY()).to.equal(1600);
      expect(await bushido.MINT_PRICE()).to.equal(ethers.parseEther("0.03"));
      expect(await bushido.MAX_PER_WALLET()).to.equal(3);
    });
  });

  describe("Whitelist Minting", function () {
    it("Should allow whitelisted addresses to mint", async function () {
      const { bushido, owner, addr1 } = await loadFixture(deployBushidoFixture);
      
      // Create merkle tree
      const leaves = [addr1.address].map(x => keccak256(x));
      const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
      const root = tree.getRoot();
      const proof = tree.getProof(keccak256(addr1.address));
      
      await bushido.setMerkleRoot(root);
      await bushido.setMintPhase(1); // WHITELIST
      
      await expect(bushido.connect(addr1).whitelistMint(1, proof, {
        value: ethers.parseEther("0.03")
      })).to.not.be.reverted;
    });
  });

  describe("Voting System", function () {
    it("Should allow token holders to vote", async function () {
      const { bushido, owner, addr1 } = await loadFixture(deployBushidoFixture);
      
      // Mint token first
      await bushido.setMintPhase(2); // PUBLIC
      await bushido.connect(addr1).mint(1, { value: ethers.parseEther("0.03") });
      
      // Create episode
      await bushido.createEpisode(1);
      
      // Vote
      await expect(bushido.connect(addr1).vote(1, 1, "option1"))
        .to.emit(bushido, "VoteCast");
    });
  });

  describe("Security", function () {
    it("Should prevent reentrancy attacks", async function () {
      // Implementation of reentrancy test
    });

    it("Should validate all inputs", async function () {
      // Input validation tests
    });
  });
});
