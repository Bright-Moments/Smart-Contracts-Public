//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
/**
 * @title Random
 * @author @brougkr
 * @notice This Smart Contract Returns An Array Of Pseudo-Random Numbers
 */
contract Random {
    /**
     * @dev Returns An Array Of Randomized Numbers
     */
    function ViewRandomNumbers(uint[] memory Array) external view returns (uint[] memory) 
    {
        require(Array.length > 0, "Input Array Length Must Be > 0");

        // Fisher-Yates shuffle algorithm
        for(uint x = Array.length; x > 1; x--) 
        {
            uint rand = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % x;
            (Array[x - 1], Array[rand]) = (Array[rand], Array[x - 1]);
        }

        // Remove duplicates
        uint[] memory result = new uint[](Array.length);
        uint count;

        for(uint x; x < Array.length; x++) 
        {
            if(!IsUnique(result, count, Array[x])) 
            {
                result[count] = Array[x];
                count++;
            }
        }

        // resize the array to remove unused slots
        uint[] memory finalResult = new uint[](count);
        for(uint x; x < count; x++) { finalResult[x] = result[x]; }

        return finalResult; // return finalized array
    }

    /**
     * @dev Returns If An Element Is Unique
     */
    function IsUnique(uint[] memory array, uint length, uint value) private pure returns (bool) 
    {
        for(uint x; x < length; x++) { if(array[x] == value) { return true; } }
        return false;
    }
}