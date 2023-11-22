// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IAdminStructure, IConvexRewardPoolL1, ICurveSwap, IStrategyConvex, IQuoter, StrategyCalculationsTricryptoL1 } from "../strategies/curve/StrategyCalculationsTricryptoL1.sol";

/// @title Mock strategy contract for calculating strategy-related values
contract StrategyCalculationsTricryptoL1Mocked is StrategyCalculationsTricryptoL1 {
    /// @dev Initializes the StrategyCalculationsTricryptoL1 contract
    /// @param _strategy The address of the StrategyConvex contract
    /// @param _quoter The address of the Quoter contract
    /// @param _adminStructure The address of the AdminStructure contract
    function StrategyCalculationsTricryptoL1Mocked__init(
        IStrategyConvex _strategy,
        IQuoter _quoter,
        IAdminStructure _adminStructure
    ) public initializer {
        initialize(_strategy, _quoter, _adminStructure);
    }

    function getAutomaticCurveMinLp(
        uint256 _depositAmount
    ) external view override returns (uint256) {
        uint256[3] memory amounts = getCurveAmounts(strategy.depositToken(), _depositAmount);
        uint256 amount = ICurveSwap(strategy.pool()).calc_token_amount(amounts, true);
        uint256 depositWithSlippage = (amount * (ONE_HUNDRED - strategy.defaultSlippageCurve())) /
            ONE_HUNDRED;
        return depositWithSlippage;
    }

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
