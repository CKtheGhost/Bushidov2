// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";

contract EmergencyPause is Pausable {
    mapping(address => bool) public pausers;
    
    modifier onlyPauser() {
        require(pausers[msg.sender], "Not authorized to pause");
        _;
    }
    
    function addPauser(address account) external onlyOwner {
        pausers[account] = true;
    }
    
    function removePauser(address account) external onlyOwner {
        pausers[account] = false;
    }
    
    function pause() external onlyPauser {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
}
