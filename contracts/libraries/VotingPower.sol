// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library VotingPower {
    function calculateVotingPower(uint256 rarity) internal pure returns (uint256) {
        if (rarity == 0) return 1;   // Common
        if (rarity == 1) return 4;   // Uncommon
        if (rarity == 2) return 9;   // Rare
        if (rarity == 3) return 16;  // Epic
        if (rarity == 4) return 25;  // Legendary
        return 1;
    }
}
