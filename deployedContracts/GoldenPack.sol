//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
contract GoldenPack is Ownable, ReentrancyGuard
{
    struct Params
    {
        uint _GoldenTokenIDCurrent;
        address _MintPass;
        address _GoldenToken;
        address _Marketplace;
        address _Operator;
    }

    Params public _Params;

    constructor()
    {
        _Params._GoldenTokenIDCurrent = 666;
        _Params._MintPass = address(0);
        _Params._GoldenToken = 0x985e1932FFd2aA4bC9cE611DFe12816A248cD2cE; // golden token mainnet
        _Params._Marketplace = 0xDaf6F80AD2AFdC45014c59bfE507ED728656D11B; // auction marketplace mainnet
        _Params._Operator = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937; // brightmoments.eth
    }

    /**
     * @dev Mints Golden Tokens and Mint Passes To Recipient
     */
    function _MintToFactory(address Recipient, uint Amount) external onlyMarketplace
    {
        IMP MintPass = IMP(_Params._MintPass);
        IERC721 GoldenToken = IERC721(_Params._GoldenToken);
        uint Start = _Params._GoldenTokenIDCurrent;
        for(uint x; x < Amount; x++) 
        { 
            MintPass._MintToFactory(Recipient, 20); 
            for(uint y; y < 4; y++) { GoldenToken.transferFrom(_Params._Operator, Recipient, Start + y); }
        }
        _Params._GoldenTokenIDCurrent = Start + 4;
    }

    /**
     * @dev Changes Golden Token TokenID
     */
    function __ChangeGoldenTokenIDCurrent(uint TokenID) external onlyOwner { _Params._GoldenTokenIDCurrent = TokenID; }

    /**
     * @dev Changes Mint Pass Address
     */
    function __ChangeMintPassAddress(address MintPass) external onlyOwner { _Params._MintPass = MintPass; }

    /**
     * @dev Changes Golden Token Address
     */
    function __ChangeGoldenTokenAddress(address GoldenToken) external onlyOwner { _Params._GoldenToken = GoldenToken; }

    /**
     * @dev Changes Marketplace Address
     */
    function __ChangeMarketplaceAddress(address Marketplace) external onlyOwner { _Params._Marketplace = Marketplace; }

    /**
     * @dev Changes Operator Address
     */
    function __ChangeOperatorAddress(address Operator) external onlyOwner { _Params._Operator = Operator; }

    /**
     * @dev onlyMarketplace Access Modifier
     */
    modifier onlyMarketplace
    {
        require(msg.sender == _Params._Marketplace, "GoldenPack: Only Marketplace");
        _;
    }
}

interface IERC721 { function transferFrom(address from, address to, uint256 tokenId) external; }
interface IMP { function _MintToFactory(address Recipient, uint Amount) external; }