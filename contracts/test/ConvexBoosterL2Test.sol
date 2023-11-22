// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Mock contract of a convex booster L2
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
contract ConvexBoosterL2Test {
    using SafeERC20 for IERC20;

    /// @dev Address of the reward pool contract.
    address public rewardPool;
    /// @dev Address of want token.
    address public want;

    /// @dev Mapping to store the deposit amounts of users.
    mapping(address => uint256) public userDeposit;

    /// @dev Initializes the ConvexBoosterL2Test contract.
    /// @param _rewardPool The address of the reward pool contract
    /// @param _want The address of the want token
    constructor(address _rewardPool, address _want) {
        rewardPool = _rewardPool;
        want = _want;
    }

    /// @dev Allows to edit the deposit amount for a specific user.
    /// @param _user The address of the user
    /// @param _deposit The new deposit amount for the user
    function editUserDeposit(address _user, uint256 _deposit) external {
        require(msg.sender == rewardPool, "NotRewardPool");
        userDeposit[_user] = _deposit;
    }

    /// @dev Allows to edit the reward pool contract address.
    /// @param _rewardPool The new address of the reward pool contract
    function editRewardPool(address _rewardPool) external {
        rewardPool = _rewardPool;
    }

    /// @dev Allows the contract owner to edit the underlying token address.
    /// @param _want The new address of the underlying token
    function editWant(address _want) external {
        want = _want;
    }

    /// @dev Returns information about the pool.
    /// @return lptoken The address of the LP token
    /// @return gauge The address of the gauge
    /// @return rewards The address of the rewards contract
    /// @return shutdown A boolean indicating if the pool is shutdown
    /// @return factory The address of the factory
    function poolInfo(
        uint256
    )
        external
        view
        returns (address lptoken, address gauge, address rewards, bool shutdown, address factory)
    {
        return (address(this), address(this), rewardPool, false, address(this));
    }

    /// @dev Allows users to deposit funds into the pool.
    /// @param _amount The amount of tokens to deposit
    /// @return A boolean indicating if the deposit was successful
    function deposit(uint256, uint256 _amount) external returns (bool) {
        IERC20(want).safeTransferFrom(msg.sender, rewardPool, _amount);
        userDeposit[msg.sender] += _amount;
        return true;
    }
}
