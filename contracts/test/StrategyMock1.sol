// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IDolletVault } from "../interfaces/dollet/IDolletVault.sol";

/// @title Mock implementation of a strategy
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
/// @notice This contract it is used to simulate reentrancy on the vault
contract StrategyMock1Base {
    IDolletVault public dolletVault;
    IERC20Upgradeable public want;
    uint256 public balanceOf;

    /// @dev Initializes the mock strategy.
    /// @param _dolletVault Address of the dollet vault
    /// @param _want  Address of the want
    constructor(IDolletVault _dolletVault, IERC20Upgradeable _want) {
        dolletVault = _dolletVault;
        want = _want;
        balanceOf = 10 ether;
    }

    /// @dev Simulates the harvestOnDeposit function on the vault.
    function harvestOnDeposit() external {
        dolletVault.deposit(0, address(0), 0);
    }

    /// @dev Simulates the harvest function on the vault.
    function harvest() external {
        // Intentionally empty, don't make it pure
    }

    /// @dev Simulates the withdraw function on the vault.
    function withdraw(address, uint256, address, uint256, bool) external {
        dolletVault.withdrawAll(address(0), 0);
    }

    /// @dev Simulates the claimRewards function on the vault.
    function claimRewards(address, address, uint256, uint256, bool) external {
        dolletVault.claimRewards(address(0), 0);
    }

    /// @dev Sets the balance of the strategy.
    function setBalanceOf(uint256 _balanceOf) public {
        balanceOf = _balanceOf;
    }

    /// @dev Returns a set amount representing the user want deposit
    function userWantDeposit(address) external pure returns (uint256) {
        return 1 ether;
    }

    /// @dev Returns a set amount representing the total want deposit
    function totalWantDeposits() external pure returns (uint256) {
        return 1 ether;
    }

    /// @dev Returns a set value representing that the token is allowed
    function allowedDepositTokens(address) external pure returns (bool, uint8) {
        return (true, 0);
    }
}

contract StrategyMock1Eth {
    IDolletVault public dolletVault;
    IERC20Upgradeable public want;
    uint256 public balanceOf;

    /// @dev Initializes the mock strategy.
    /// @param _dolletVault Address of the dollet vault
    /// @param _want  Address of the want
    constructor(IDolletVault _dolletVault, IERC20Upgradeable _want) {
        dolletVault = _dolletVault;
        want = _want;
        balanceOf = 10 ether;
    }

    /// @dev Simulates the harvestOnDeposit function on the vault.
    function harvestOnDeposit() external {
        dolletVault.deposit(0, address(0), 0);
    }

    /// @dev Simulates the harvest function on the vault.
    function harvest() external {
        // Intentionally empty, don't make it pure
    }

    /// @dev Simulates the withdraw function on the vault.
    function withdraw(address, uint256, address, uint256, bool) external {
        dolletVault.withdrawAll(address(0), 0, false);
    }

    /// @dev Simulates the claimRewards function on the vault.
    function claimRewards(address, address, uint256, uint256, bool) external {
        dolletVault.claimRewards(address(0), 0, false);
    }

    /// @dev Sets the balance of the strategy.
    function setBalanceOf(uint256 _balanceOf) public {
        balanceOf = _balanceOf;
    }

    /// @dev Returns a set amount representing the user want deposit
    function userWantDeposit(address) external pure returns (uint256) {
        return 1 ether;
    }

    /// @dev Returns a set amount representing the total want deposit
    function totalWantDeposits() external pure returns (uint256) {
        return 1 ether;
    }

    /// @dev Returns a set value representing that the token is allowed
    function allowedDepositTokens(address) external pure returns (bool, uint8) {
        return (true, 0);
    }
}
