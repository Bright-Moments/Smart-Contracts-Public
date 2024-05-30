//SPDX-License-Identifier: MIT
/**
 * @dev: @brougkr
 */
pragma solidity 0.8.19;
interface IMPMX // Helper Interface For MPMX Live-Minting
{ 
    function ViewArtistID(uint TokenID) external view returns(uint);
    function _LiveMintBurn(uint TokenID) external returns(address, uint);
    function ViewArtistIDsByTokenIDs(uint[] calldata TokenIDs) external view returns(uint[] memory);
}