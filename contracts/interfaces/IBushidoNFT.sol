// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBushidoNFT {
    function getVotingPower(uint256 tokenId) external view returns (uint256);
    function tokenClan(uint256 tokenId) external view returns (uint256);
    function tokenRarity(uint256 tokenId) external view returns (uint256);
}
