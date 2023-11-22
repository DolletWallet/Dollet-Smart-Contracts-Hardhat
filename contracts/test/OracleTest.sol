// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Mock implementation of an oracle
/// @dev This contract is used for testing purposes only and will not be used in production.
/// @dev The contract allows modifying different values without access control for ease of use.
contract OracleTest {
    uint8 public decimals;
    int256 public latestAnswer;

    /// @dev Initializes the OracleTest contract.
    /// @param _decimals The number of decimal places for the oracle value.
    /// @param _latestAnswer The latest answer reported by the oracle.
    constructor(uint8 _decimals, int256 _latestAnswer) {
        decimals = _decimals;
        latestAnswer = _latestAnswer;
    }

    /// @dev Edits the number of decimal places for the oracle value.
    /// @param _decimals The new number of decimal places.
    function editDecimals(uint8 _decimals) external {
        decimals = _decimals;
    }

    /// @dev Edits the latest answer reported by the oracle.
    /// @param _latestAnswer The new latest answer.
    function editLatestAnswer(int256 _latestAnswer) external {
        latestAnswer = _latestAnswer;
    }
}
