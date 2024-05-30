//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
contract Helper is Ownable, ReentrancyGuard
{   
    bool Active;
    address ABCORE = 0xe745243b82ebC46E5c23d9B1B968612c65d45f3d;
    mapping(address=>uint) public LastCreatedTimestamp;

    /**
     * @dev Starts Project
     */
    function StartProject(
        string memory _projectName,
        address _artistAddress,
        uint256 _pricePerTokenInWei
    ) external nonReentrant {
        require(Active, "Helper: Not Active");
        require(ViewCooldown(msg.sender) == 0, "Helper: Cooldown Incomplete");
        LastCreatedTimestamp[msg.sender] = block.timestamp;
        IArtBlocksCore(ABCORE).addProject(_projectName, _artistAddress, _pricePerTokenInWei);
    }

    /**
     * @dev Returns Unix Seconds Until Cooldown Expires
     */
    function ViewCooldown(address Wallet) public view returns (uint)
    {
        if(block.timestamp > LastCreatedTimestamp[Wallet] + 30 days) { return 0; }
        else { return ((LastCreatedTimestamp[Wallet] + 30 days) - block.timestamp); }
    }

    /**
     * @dev Toggles The Active State Of The Contract
     */
    function ToggleActive() external onlyOwner { Active = !Active; }
}

interface IArtBlocksCore { function addProject(string calldata Name, address ArtistAddress, uint PricePerTokenInWei) external; }