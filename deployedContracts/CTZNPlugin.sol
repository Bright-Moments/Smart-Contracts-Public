//SPDX-License-Identifier: MIT
/**
 * @dev: @brougkr
 */
pragma solidity ^0.8.19;
abstract contract CTZNPlugin
{
    address public immutable CTZN = 0xb11BDEAf6249627B84B56A6Aff3Edb4eadd743fc;
    event RewardRatesChanged(uint[] RewardIndexes, uint[] RewardRates);
    mapping(uint=>uint) public _RewardRates;

    /**
     * @dev Modifies The Reward Rate Of A CTZN Enabled Contract
     */
    function ModifyRewardRates(uint[] calldata RewardIndexes, uint[] calldata RewardRates) external onlyCTZN
    {   
        require(RewardIndexes.length == RewardRates.length, "CTZNPlugin: Array Lengths Must Match");
        for(uint RewardIndex; RewardIndex < RewardIndexes.length; RewardIndex++)
        {
            _RewardRates[RewardIndexes[RewardIndex]] = RewardRates[RewardIndex];
        }
        emit RewardRatesChanged(RewardIndexes, RewardRates);
    }

    /**
     * @dev Modifier Ensuring `msg.sender` == `$CTZN Contract`
     */
    modifier onlyCTZN
    {
        require(msg.sender == CTZN, "Sender Is Not CTZN Contract");
        _;
    }
}

interface ICTZN { function IncrementCTZN(address Recipient, uint Amount) external; }