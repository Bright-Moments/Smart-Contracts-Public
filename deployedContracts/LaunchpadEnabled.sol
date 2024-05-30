//SPDX-License-Identifier: MIT
/**
 * @title LaunchpadEnabled
 * @author @brougkr
 * @notice: This Contract Is Used To Enable Launchpad Functionality On Your Smart Contract
 * @notice: This Contract Should Be Imported and Included In The `is` Portion Of The Contract Declaration, ex. `contract NFT is Ownable, LaunchpadEnabled`
 * @notice: You Can Copy Or Modify The Example Functions Below To Implement The Two Functions In Your Contract
 */
pragma solidity 0.8.19;
abstract contract LaunchpadEnabled
{
    /**
     * @dev The Launchpad Address
     */
    address public _LAUNCHPAD = 0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700;

    /**
     * @dev Updates The Launchpad Address From Launchpad (batch upgrade)
     */ 
    function _____NewLaunchpadAddress(address NewAddress) external onlyLaunchpad { _LAUNCHPAD = NewAddress; }

    /**
     * @dev Access Control Needed For A Contract To Be Able To Use The Launchpad
    */
    modifier onlyLaunchpad()
    {
        require(_LAUNCHPAD == msg.sender, "onlyLaunchpad: Caller Is Not Launchpad");
        _;
    }
}