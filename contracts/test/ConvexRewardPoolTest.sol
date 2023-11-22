// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IERC20Upgradeable, SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
interface Booster {
    /// @notice Allows to see the user deposit amount
    /// @param _user Address of the user
    /// @return Amount of the user deposit
    function userDeposit(address _user) external view returns (uint256);

    /// @notice Allows to edit the user deposit amount
    /// @param _user Address of the user
    /// @param _deposit Amount to set for the user
    function editUserDeposit(address _user, uint256 _deposit) external;

    /// @notice Returns the address of the want address
    /// @return Address of the want contract
    function want() external returns (address);
}

/// @title Common Convex Reward Pool Functions
/// @dev Simulates the ConvexRewardPool
/// @dev This contract is used for testing purposes only and will not be used in production.
/// @dev The contract allows modifying different values without access control for ease of use.
abstract contract ConvexRewardPoolBaseTest {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @dev Address of the CRV token.
    address public crv;
    /// @dev Address of the CVX token.
    address public cvx;
    /// @dev Address of the booster contract.
    address public booster;
    /// @dev Address of the strategy contract.
    address public strategy;
    /// @dev Nonce used for generating random numbers.
    uint256 public nonce;
    /// @dev Upper bound for the random number generation.
    uint256 public upperBound = 1 ether;
    /// @dev Lower bound for the random number generation.
    uint256 public lowerBound = 10 ether;
    /// @dev Stores the next reward amount
    uint256 public nextRewardAmount = 1 ether;
    /// @dev Stores the cvx reward percentage
    uint256 public cvxRewardPercentage = 20 ether; // 20% from CVR amount
    /// @dev The next reward distribution date
    uint256 public nextRewardDistributionDate = block.timestamp;
    /// @dev Simulates a delay in rewards accumulation
    uint256 public rewardDelay = 600; // 10 minutes
    /// @dev Simulates new rewards every second
    uint256 public rewardPerSecond = 5787037037037; // 0.5 tokens per day

    /// @dev Initializes the ConvexRewardPoolBaseTest contract.
    /// @param _crv Address of the CRV token.
    /// @param _cvx Address of the CVX token.
    /// @param _booster Address of the booster contract.
    constructor(address _crv, address _cvx, address _booster) {
        crv = _crv;
        cvx = _cvx;
        booster = _booster;
    }

    /// @dev Sets the upper bound for the random number generation.
    /// @param _upperBound The upper bound value.
    function setUpperBound(uint256 _upperBound) external {
        upperBound = _upperBound;
    }

    /// @dev Sets the lower bound for the random number generation.
    /// @param _lowerBound The lower bound value.
    function setLowerBound(uint256 _lowerBound) external {
        lowerBound = _lowerBound;
    }

    /// @dev Generates a random number using the nonce, used to send random prize amounts
    /// @return The generated random number.
    function generateRandomNumber() public returns (uint256) {
        nonce++;
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        );
        uint256 range = lowerBound; // Upper bound - Lower bound
        return (randomNumber % range) + upperBound; // Lower bound + Random number in the range
    }

    /// @dev Gets the balance of a user's deposit.
    /// @param account The user's account address.
    /// @return The balance of the user's deposit.
    function balanceOf(address account) external view returns (uint256) {
        return Booster(booster).userDeposit(account);
    }

    /// @dev Edits the CRV token address.
    /// @param _crv The new CRV token address.
    function editCRV(address _crv) external {
        crv = _crv;
    }

    /// @dev Edits the CVX token address.
    /// @param _cvx The new CVX token address.
    function editCVX(address _cvx) external {
        cvx = _cvx;
    }

    /// @dev Edits the booster contract address.
    /// @param _booster The new booster contract address.
    function editBooster(address _booster) external {
        booster = _booster;
    }

    /// @dev Edits the strategy contract address.
    /// @param _strategy The new strategy contract address.
    function editStrategy(address _strategy) external {
        strategy = _strategy;
    }

    /// @dev Calculates the reward amount increment every second
    function _getUpdatedReward() internal view returns (uint256) {
        return
            nextRewardAmount + (rewardPerSecond * (block.timestamp - nextRewardDistributionDate));
    }

    /// @dev Calculates the reward in CVX based on the reward of CRV
    /// @param _crvAmount The amount of CRV amount.
    /// @return returns the amount of cvx rewards to get
    function getCVXAmount(uint256 _crvAmount) public view returns (uint256) {
        return (_crvAmount * cvxRewardPercentage) / 100 ether;
    }

    /// @dev Edits the booster contract address.
    /// @param _cvxRewardPercentage The cvx reward percentage
    function editCvxRewardPercentage(uint256 _cvxRewardPercentage) external {
        require(_cvxRewardPercentage <= 100 ether, "cvxRewardPercentageTooHigh");
        cvxRewardPercentage = _cvxRewardPercentage;
    }

    /// @dev Edits the next Reward Distribution Date
    /// @param _nextRewardDistributionDate new reward distribution date
    function editNextRewardDistributionDate(uint256 _nextRewardDistributionDate) external {
        nextRewardDistributionDate = _nextRewardDistributionDate;
    }

    /// @dev Edits the reward delay
    /// @param _rewardDelay The rewardDelay added after each claim
    function editRewardDelay(uint256 _rewardDelay) external {
        rewardDelay = _rewardDelay;
    }

    /// @dev Edits the reward per second
    /// @param _rewardPerSecond The rewardDelay added after each claim
    function editRewardPerSecond(uint256 _rewardPerSecond) external {
        rewardPerSecond = _rewardPerSecond;
    }
}

/// @title Convex Reward Pool Functions for Layer 1
/// @dev Simulates the ConvexRewardPool
/// @dev This contract is used for testing purposes only and will not be used in production.
/// @dev The contract allows modifying different values without access control for ease of use.
contract ConvexRewardPoolL1Test is ConvexRewardPoolBaseTest {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Initializes the ConvexRewardPoolL1Test contract.
    /// @param _crv Address of the CRV token.
    /// @param _cvx Address of the CVX token.
    /// @param _booster Address of the booster contract.
    constructor(
        address _crv,
        address _cvx,
        address _booster
    ) ConvexRewardPoolBaseTest(_crv, _cvx, _booster) {}

    /// @dev Withdraws a specified amount from the contract.
    /// @param _amount The amount to withdraw.
    function withdrawAndUnwrap(uint256 _amount, bool) external {
        uint256 _userDeposited = Booster(booster).userDeposit(msg.sender);
        require(_userDeposited >= _amount, "AmountExceedsDeposit");
        Booster(booster).editUserDeposit(msg.sender, _userDeposited - _amount);
        IERC20Upgradeable(Booster(booster).want()).safeTransfer(msg.sender, _amount);
    }

    /// @dev Withdraws all the deposits for a user.
    function withdrawAllAndUnwrap(bool) external {
        uint256 _userDeposited = Booster(booster).userDeposit(msg.sender);
        if (_userDeposited == 0) return;
        Booster(booster).editUserDeposit(msg.sender, 0);
        IERC20Upgradeable(Booster(booster).want()).safeTransfer(msg.sender, _userDeposited);
    }

    /// @dev Gets the reward for a user.
    function getReward() external {
        address _strategy = strategy;
        uint256 _userDeposited = Booster(booster).userDeposit(_strategy);
        if (_userDeposited == 0 || nextRewardDistributionDate > block.timestamp) return;
        uint256 amount = _getUpdatedReward();
        nextRewardDistributionDate = block.timestamp + rewardDelay;
        nextRewardAmount = generateRandomNumber();
        IERC20Upgradeable(crv).safeTransfer(_strategy, amount);
        IERC20Upgradeable(cvx).safeTransfer(_strategy, getCVXAmount(amount));
    }

    /// @dev Gets the earned data for a user.
    /// @return claimable The array of earned data.
    function earned(address) external view returns (uint256) {
        uint256 _userDeposited = Booster(booster).userDeposit(strategy);
        if (_userDeposited == 0 || nextRewardDistributionDate > block.timestamp) return 0;
        return _getUpdatedReward();
    }
}

/// @title Convex Reward Pool Functions for Layer 2
/// @dev Simulates the ConvexRewardPool
/// @dev This contract is used for testing purposes only and will not be used in production.
/// @dev The contract allows modifying different values without access control for ease of use.
contract ConvexRewardPoolL2Test is ConvexRewardPoolBaseTest {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Struct for storing earned data.
    struct EarnedData {
        address token;
        uint256 amount;
    }

    /// @dev Initializes the ConvexRewardPoolL2Test contract.
    /// @param _crv Address of the CRV token.
    /// @param _booster Address of the booster contract.
    constructor(
        address _crv,
        address _cvx,
        address _booster
    ) ConvexRewardPoolBaseTest(_crv, _cvx, _booster) {}

    /// @dev Withdraws a specified amount from the contract.
    /// @param _amount The amount to withdraw.
    function withdraw(uint256 _amount, bool) external {
        uint256 _userDeposited = Booster(booster).userDeposit(msg.sender);
        require(_userDeposited >= _amount, "AmountExceedsDeposit");
        Booster(booster).editUserDeposit(msg.sender, _userDeposited - _amount);
        IERC20Upgradeable(Booster(booster).want()).safeTransfer(msg.sender, _amount);
    }

    /// @dev Withdraws all the deposits for a user.
    function withdrawAll(bool) external {
        uint256 _userDeposited = Booster(booster).userDeposit(msg.sender);
        if (_userDeposited == 0) return;
        Booster(booster).editUserDeposit(msg.sender, 0);
        IERC20Upgradeable(Booster(booster).want()).safeTransfer(msg.sender, _userDeposited);
    }

    /// @dev Gets the reward for a user.
    function getReward(address) external {
        address _strategy = strategy;
        uint256 _userDeposited = Booster(booster).userDeposit(_strategy);
        if (_userDeposited == 0 || nextRewardDistributionDate > block.timestamp) return;
        uint256 amount = _getUpdatedReward();
        nextRewardDistributionDate = block.timestamp + rewardDelay;
        nextRewardAmount = generateRandomNumber();
        IERC20Upgradeable(crv).safeTransfer(_strategy, amount);
    }

    /// @dev Gets the earned data for a user.
    /// @return claimable The array of earned data.
    function earned(address) external view returns (EarnedData[] memory claimable) {
        uint256 _userDeposited = Booster(booster).userDeposit(strategy);
        EarnedData[] memory result = new EarnedData[](2);
        uint256 crvAmount = (_userDeposited == 0 || nextRewardDistributionDate > block.timestamp)
            ? 0
            : _getUpdatedReward();
        result[0] = EarnedData(crv, crvAmount);
        result[1] = EarnedData(cvx, 0);
        return result;
    }
}
