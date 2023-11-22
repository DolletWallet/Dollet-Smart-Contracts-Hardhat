// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStrategyConvexPayable } from "../interfaces/dollet/IStrategyConvex.sol";

interface ITricryptoVault {
    function deposit(uint256 _amount, IERC20 _token, uint256 _minWant) external payable;

    function withdrawAll(address _token, uint256 _minCurveOutput, bool _useEth) external;

    function claimRewards(address _token, uint256 _minCurveOutput, bool _useEth) external;
}

/// @title Mock contract of an Investor contract
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
contract InvestorTest {
    using SafeERC20 for IERC20;

    /// @notice The address of the vault contract
    ITricryptoVault public vault;

    /// @dev Allows to initialize the contract
    /// @param _vault Address of the vault to be set
    constructor(ITricryptoVault _vault) {
        vault = _vault;
    }

    // This contract can't receive native token

    /// @dev Allows to deposit in the vault from a smart contract
    /// @param _token address of the token to deposit
    /// @param _amount amount to deposit
    function deposit(IERC20 _token, uint256 _amount) public payable {
        _token.transferFrom(msg.sender, address(this), _amount);
        _token.approve(address(vault), _amount);
        vault.deposit(_amount, _token, 0);
    }

    /// @dev Allows to withdraw the tokens of the vault from a smart contract
    /// @param _token address of the token to deposit
    /// @param _minCurveOutput minimum amount expectec
    /// @param _useEth whether to withdraw using native token
    function withdrawAll(address _token, uint256 _minCurveOutput, bool _useEth) public {
        vault.withdrawAll(_token, _minCurveOutput, _useEth);
    }

    /// @dev Allows to claim reards of the vault from a smart contract
    /// @param _token address of the token to deposit
    /// @param _minCurveOutput minimum amount expectec
    /// @param _useEth whether to withdraw using native token
    function claimRewards(address _token, uint256 _minCurveOutput, bool _useEth) public {
        vault.claimRewards(_token, _minCurveOutput, _useEth);
    }
}
