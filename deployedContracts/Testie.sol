// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { ERC721A } from "./ERC721A.sol";
contract Testie is ERC721A
{
    constructor() ERC721A("","") 
    {
        _mint(msg.sender, 15);
    }

    function generateEncodedImage(uint256 tokenId) public pure returns (string memory) {
        // You should implement your own algorithm to generate SVG based on the tokenId
        // In this example, we will generate a simple circle with a random position and radius
        uint256 x = uint256(keccak256(abi.encodePacked(tokenId, "x"))) % 100;
        uint256 y = uint256(keccak256(abi.encodePacked(tokenId, "y"))) % 100;
        uint256 r = uint256(keccak256(abi.encodePacked(tokenId, "r"))) % 50;

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="10000" height="100000">',
            '<circle cx="', toString(x), '" cy="', toString(y), '" r="', toString(r), '" fill="black" />',
            '</svg>'
        ));
    }

    function tokenURI(uint TokenID) public view override returns (string memory)
    {
        return generateEncodedImage(TokenID);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) { return "0"; }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}