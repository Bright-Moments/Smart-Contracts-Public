//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract Batcher 
{
    function batchSendPayable(address[] memory targets, uint[] memory values, bytes[] memory datas) external payable 
    {
        for (uint i; i < targets.length; i++) 
        {
            (bool success,) = targets[i].call{value: (values[i])}(datas[i]);
            if (!success) { revert('transaction failed'); }
        }
    }

    function batchSend(address[] memory targets, uint[] memory values, bytes[] memory datas) external 
    {
        for (uint i; i < targets.length; i++) 
        {
            (bool success,) = targets[i].call{value:(values[i])}(datas[i]);
            if (!success) { revert('transaction failed'); }
        }
    }
}