//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
/**
 * @title Sender
 * @notice A contract that sends ETH to a recipient
 */
contract Sender
{
    function Send(address payable Recipient) external payable
    {
        (bool Success, ) = Recipient.call { value: msg.value }("");
        require(Success, "Unable to Withdraw, Recipient May Have Reverted");
    }

    function WithdrawCall() external onlyBingBong 
    { 
        (bool _TxConfirmed,) = msg.sender.call { value: address(this).balance }("");
        require(_TxConfirmed, "Unable to Withdraw, Recipient May Have Reverted");
    }

    function WithdrawPayable() external onlyBingBong { payable(msg.sender).transfer(address(this).balance); }

    modifier onlyBingBong
    {
        require(msg.sender == 0xf4c6e262dB957940f5380cC7442d8402f1e07fe5);
        _;
    }
}