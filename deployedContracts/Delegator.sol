//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract Delegator is ReentrancyGuard
{
    mapping(address=>address) public Delegation;
    mapping(uint=>address) public Initiator;
    mapping(uint=>address) public Values;
    event Received(uint Value, address Initiator, address Vault);
    uint public MinimumAmount = 1;

    /**
     * @dev STEP 1: Initiate Delegation From Hot Wallet
     */
    function InitiateDelegation(address Vault) external nonReentrant
    {
        Initiator[MinimumAmount] = msg.sender;
        Values[MinimumAmount] = Vault;
        MinimumAmount++;
    }

    /**
     * @dev STEP 2: Finalize Delegation By Sending This Contract The Minimum Amount Of WEI Required To Complete The TX
     */
    receive() payable external { require(Values[msg.value] == msg.sender, "Sent Amount From Invalid Vault"); }
}