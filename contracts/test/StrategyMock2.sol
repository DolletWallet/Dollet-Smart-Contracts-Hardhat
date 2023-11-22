// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { StrategyConvexTricryptoNativeL1 } from "../strategies/curve/StrategyConvexTricryptoNativeL1.sol";
import { StrategyConvexBicryptoL2 } from "../strategies/curve/StrategyConvexBicryptoL2.sol";

/// @title Mock implementation of a strategy
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
/// @notice This contract it is used to simulate a reinitialize in the StratFeeManager
contract StrategyMock2 is StrategyConvexBicryptoL2 {
    /// @notice Allows to simulate the reinitialize in the StratFeeManager
    /// @dev This case could happen with a future upgrade
    function reinitializeStratFeeManager(CommonAddresses calldata _commonAddresses) external {
        __StratFeeManager_init(_commonAddresses);
    }
}

/// @title StrategyMock2Tricrypto
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
/// @notice This contract it is used to simulate a reinitialize in the StratFeeManager
contract StrategyMock2Tricrypto is StrategyConvexTricryptoNativeL1 {
    /// @notice Allows to simulate the reinitialize in the StratFeeManager
    /// @dev This case could happen with a future upgrade
    function reinitializeStratFeeManager(CommonAddresses calldata _commonAddresses) external {
        __StratFeeManager_init(_commonAddresses);
    }
}
