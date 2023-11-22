// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IConvexRewardPoolL1, StrategyCalculationsL1 } from "../strategies/curve/StrategyCalculationsL1.sol";

/// @title StrategyCalculationsL1Mock contract for calculating strategy-related values
contract StrategyCalculationsL1Mock is StrategyCalculationsL1 {
    /**
     * @notice Estimates the amoung of CVX rewards that the strategy can receive
     * @dev The amount of CVX is determined by the amount of CVX
     * @param _crvAmount The amount of crv rewards
     * @return The amount of cvx rewards tokens available to be claimed
     */
    function estimateCVXRewards(uint256 _crvAmount) public view override returns (uint256) {
        return IConvexRewardPoolL1(strategy.rewardPool()).getCVXAmount(_crvAmount);
    }
}
