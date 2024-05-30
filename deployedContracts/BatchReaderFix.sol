//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
contract BatchReader
{  
    /**
     * @dev Batch Returns Owners Of Collection
     */
    function readNFTOwners(
        address[] calldata NFTAddresses, 
        uint Range
    ) public view returns (address[][] memory) {
        address[][] memory Owners = new address[][](NFTAddresses.length);
        for(uint x; x < NFTAddresses.length; x++)
        {
            IERC721 NFT = IERC721(NFTAddresses[x]);
            address[] memory temp = new address[](Range);
            uint counter;
            for(uint y; y <= Range; y++)
            {
                try NFT.ownerOf(y) 
                {
                    if(NFT.ownerOf(y) != address(0))
                    {
                        temp[counter] = NFT.ownerOf(y);
                        counter++;   
                    }
    
                } catch { }
            }
            address[] memory FormattedOwnedIDs = new address[](counter);
            uint index;
            for(uint z; z < counter; z++)
            {
                if(temp[z] != address(0))
                {
                    FormattedOwnedIDs[index] = temp[z];
                    index++;
                }
            }
            Owners[x] = FormattedOwnedIDs;
        }
        return Owners;
    }
}

interface IERC721
{
    function ownerOf(uint) external view returns (address);

}