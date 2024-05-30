//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Test is ERC20
{
    constructor() ERC20("BRTA1", "BRTA1") 
    {
        _mint(msg.sender, 10000000000);
    }

    function mint(address recipient, uint amount) external
    {
        _mint(recipient, amount);
    }
}
