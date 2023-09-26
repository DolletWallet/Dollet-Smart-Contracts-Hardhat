// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @dev Interface for interacting with a Vault contract.
interface IDolletVault {
    /// @dev Struct representing deposit limits for a token.
    struct DepositLimit {
        address token;
        uint256 minAmount;
        uint256 maxAmount;
    }

    /// @dev Returns the balance of the Vault.
    function balance() external view returns (uint256);

    /// @dev Returns the address of the token that the Vault holds.
    function want() external view returns (address);

    /// @dev Returns the address of the strategy used by the Vault.
    function strategy() external view returns (address);

    /// @dev Returns the address of the admin structure contract used by the Vault.
    function adminStructure() external view returns (address);

    /// @dev Deposits a specific amount of tokens into the Vault.
    /// @param _amount The amount of tokens to deposit.
    /// @param _token The address of the token to deposit.
    /// @param _minWant The minimum amount of tokens to receive in return.
    function deposit(uint256 _amount, address _token, uint256 _minWant) external;

    /// @dev Withdraws all tokens of a specific type from the Vault.
    /// @param _token The address of the token to withdraw.
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve.
    function withdrawAll(address _token, uint256 _minCurveOutput) external;

    /// @dev Withdraws all tokens of a specific type from the Vault.
    /// @param _token The address of the token to withdraw.
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve.
    /// @param _useEth Indicates whether to withdraw ETH or not
    function withdrawAll(address _token, uint256 _minCurveOutput, bool _useEth) external;

    /// @dev Claims rewards from the Vault for a specific token.
    /// @param _token The address of the token to claim rewards for.
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve.
    function claimRewards(address _token, uint256 _minCurveOutput) external;

    /// @dev Claims rewards from the Vault for a specific token.
    /// @param _token The address of the token to claim rewards for.
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve.
    /// @param _useEth Indicates whether to withdraw ETH or not
    function claimRewards(address _token, uint256 _minCurveOutput, bool _useEth) external;

    /// @dev Estimates the withdrawal details for a specific user and token.
    /// @param _user The address of the user.
    /// @param _token The address of the token to withdraw.
    /// @param _slippage The allowed slippage percentage.
    /// @return minCurveOutput The minimum amount of tokens to receive from Curve.
    /// @return withdrawable The amount of tokens available that will be accepted from the withdrawal.
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _slippage
    ) external view returns (uint256 minCurveOutput, uint256 withdrawable);

    /// @dev Estimates the rewards details for a specific user and token.
    /// @param _user The address of the user.
    /// @param _token The address of the token to check rewards for.
    /// @param _slippage The allowed slippage percentage.
    /// @return minCurveOutput The minimum amount of tokens to receive from Curve.
    /// @return claimable The amount of tokens claimable as rewards.
    function estimateRewards(
        address _user,
        address _token,
        uint256 _slippage
    ) external view returns (uint256 minCurveOutput, uint256 claimable);

    /// @dev Estimates the total rewards claimable for all users for a specific token.
    /// @param _token The address of the token to check rewards for.
    /// @param _slippage The allowed slippage percentage.
    /// @return claimable The total amount of tokens claimable as rewards.
    function estimateAllUsersRewards(
        address _token,
        uint256 _slippage
    ) external view returns (uint256 claimable);

    /**
     * @dev Estimates the deposit details for a specific token and amount.
     * @param _token The address of the token to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _slippage The allowed slippage percentage.
     * @return amountLP The amount of LP tokens to receive from the vault
     * @return amountWant The minimum amount of LP tokens to get from curve deposit
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 amountLP, uint256 amountWant);

    /// @dev Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount.
    /// @param _token The address of the token to withdraw.
    /// @param _amount The maximum amount of tokens to withdraw.
    /// @param _slippage The allowed slippage percentage.
    /// @return The minimum amount of tokens to receive from Curve.
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to get on curve deposit
    /// @param _token The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return The amount of LP tokens to get
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Estimates the amount of tokens to swap from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _slippage The allowed slippage percentage
    /// @return estimate The estimated amount of tokens to receive after the swap
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 estimate);

    /**
     * @dev Returns the amount of tokens deposited by a specific user in the indicated token
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return The amount of tokens deposited by the user.
     */
    function userDeposit(address _user, address _token) external view returns (uint256);

    /**
     * @dev Returns the total amount of tokens deposited in the strategy in the indicated token
     * @param _token The address of the token.
     * @return The total amount of tokens deposited.
     */
    function totalDeposits(address _token) external view returns (uint256);

    /// @dev Handles the case where tokens get stuck in the Vault. Allows the admin to send the tokens to the super admin
    /// @param _token The address of the stuck token.
    function inCaseTokensGetStuck(address _token) external;

    /// @dev Edits the deposit limits for specific tokens.
    /// @param _depositLimits The array of DepositLimit structs representing the new deposit limits.
    function editDepositLimits(DepositLimit[] calldata _depositLimits) external;
}
