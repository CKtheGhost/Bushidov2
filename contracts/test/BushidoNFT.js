const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BushidoNFT", function () {
  it("should mint", async function () {
    const [owner, user] = await ethers.getSigners();
    const BushidoNFT = await ethers.getContractFactory("BushidoNFT");
    const contract = await BushidoNFT.deploy();
    await contract.waitForDeployment();
    await contract.connect(owner).activateMint();
    await contract.connect(user).mint(1, { value: ethers.parseEther("0.08") });
    expect(await contract.balanceOf(user.address)).to.equal(1n);
  });

  it("calculates voting power", async function () {
    const [owner] = await ethers.getSigners();
    const BushidoNFT = await ethers.getContractFactory("BushidoNFT");
    const contract = await BushidoNFT.deploy();
    await contract.waitForDeployment();
    await contract.activateMint();
    await contract.mint(1, { value: ethers.parseEther("0.08") });
    const tokenId = await contract.tokenOfOwnerByIndex(owner.address, 0);
    const rarity = await contract.tokenRarity(tokenId);
    const expected = rarity ** 2n;
    const votingPower = await contract.getVotingPower(owner.address);
    expect(votingPower).to.equal(expected);
  });
});
