// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IStrategyCalculationsTwocrypto as IStrategyCalculations } from "../../interfaces/dollet/IStrategyCalculations.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { AggregatorV3Interface } from "../../interfaces/chainlink/AggregatorV3Interface.sol";
import { IConvexBoosterL1, IConvexRewardPoolL1 } from "../../interfaces/convex/IConvex.sol";
import { IStrategyConvex } from "../../interfaces/dollet/IStrategyConvex.sol";
import { IGaugeFactory } from "../../interfaces/curve/IGaugeFactory.sol";
import { ICurveSwap } from "../../interfaces/curve/ICurveSwap.sol";
import { StratFeeManager } from "../common/StratFeeManager.sol";
import { IQuoter } from "../../interfaces/common/IQuoter.sol";
import { IERC20 } from "../../interfaces/common/IERC20.sol";
import { UniV3Actions } from "../../utils/UniV3Actions.sol";

/// @title Strategy intermediary to interact with defi protocols
/// @notice The StrategyConvexBicryptoL1 contract is a crucial component of a project focused on optimizing
/// yield farming on Convex Finance. It facilitates the management of a strategy by interacting with
/// external contracts, such as a Convex booster, a calculations contract, and a Curve swap pool. The contract
/// allows users to deposit funds, claim rewards, and perform harvesting operations. It supports multiple tokens
/// for deposit and incorporates checks and validations to ensure secure operations. With features like token
/// swapping and reinvestment strategies, the contract helps users maximize their yields and earn rewards effectively.
contract StrategyConvexBicryptoL1 is IStrategyConvex, StratFeeManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Address of the booster contract
    IConvexBoosterL1 public booster;
    /// @notice Address of the calculations contract
    IStrategyCalculations public calculations;
    bool public isPanicActive; // True if panic is active
    address public want; // Curve LP Token
    address public pool; // Curve swap pool
    address public depositToken; // Token used to reinvest in harvest
    address public rewardPool; // Convex base reward pool
    uint256 public pid; // Convex booster poolId
    uint256 public poolSize; // Pool size
    uint256 public depositIndex; // Index of depositToken in pool
    uint256 public lastHarvest; // Last timestamp when the harvest occurred
    uint256 public totalWantDeposits; // Total of deposits in Curve LP
    uint256 public defaultSlippageCurve; // Curve slippage used in harvest
    uint256 public defaultSlippageUniswap; // Uniswap slippage used in harvest
    mapping(address => uint256) public userWantDeposit; // Total user deposited in Curve LP
    mapping(address => uint256) public minimumToHarvest; // Minimum amount to execute reinvestment in harvest
    mapping(address => mapping(address => bytes)) public paths; // From => To returns path for Uniswap
    mapping(address => AggregatorV3Interface) public oracle; // Price oracle for a token
    mapping(address => PoolToken) public allowedDepositTokens; // Indicates what token is allowed
    address[] private rewardTokens; // List of the reward tokens
    address[] public listAllowedDepositTokens; // List of the allowed tokens

    /// @dev Modifier to restrict access to vault only.
    modifier onlyVault() {
        require(msg.sender == vault, "InvalidCaller");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param _want The address of the curve lpToken
    /// @param _pool The address of the curve swap pool
    /// @param _booster The address of the Convex booster contract
    /// @param _pid The pool ID of the Convex booster
    /// @param _depositToken The token sent to the pool to receive want
    /// @param _oracles The array of oracle token and oracle address pairs
    /// @param _params The array of poolSize and depositIndex parameters
    /// @param _defaultSlippages The default slippages for curve and Uniswap
    /// @param rewardInfo The reward token addresses and minimum amounts for rewards
    /// @param _commonAddresses The addresses of common contracts
    function initialize(
        address _want,
        address _pool,
        address _booster,
        uint256 _pid,
        address _depositToken,
        Oracle[] calldata _oracles,
        uint256[] calldata _params, // [poolSize, depositIndex]
        DefaultSlippages calldata _defaultSlippages,
        RewardInfo calldata rewardInfo,
        CommonAddresses calldata _commonAddresses
    ) public initializer {
        __StratFeeManager_init(_commonAddresses);
        require(_want != address(0), "ZeroWant");
        require(_pool != address(0), "ZeroPool");
        require(_booster != address(0), "ZeroBooster");
        require(_depositToken != address(0), "ZeroDeposit");
        require(ONE_HUNDRED >= _defaultSlippages.curve, "InvalidDefaultSlippageCurve");
        require(ONE_HUNDRED >= _defaultSlippages.uniswap, "InvalidDefaultSlippageUniswap");
        for (uint256 i; i < _oracles.length; i++) {
            require(_oracles[i].token != address(0), "ZeroOracleToken");
            require(_oracles[i].oracle != address(0), "ZeroOracleOracle");
            oracle[_oracles[i].token] = AggregatorV3Interface(_oracles[i].oracle);
        }
        defaultSlippageCurve = _defaultSlippages.curve;
        defaultSlippageUniswap = _defaultSlippages.uniswap;
        (want, pool, pid, depositToken) = (_want, _pool, _pid, _depositToken);
        booster = IConvexBoosterL1(_booster);
        poolSize = _params[0];
        depositIndex = _params[1];
        (, , , rewardPool, , ) = booster.poolInfo(_pid);

        addRewardToken(rewardInfo.tokens, rewardInfo.minAmount);

        // Adding valid tokens
        uint256 _poolSize = poolSize;
        for (uint256 i; i < _poolSize; i++) {
            address coin = ICurveSwap(_pool).coins(i);
            allowedDepositTokens[coin] = PoolToken(true, uint8(i));
            listAllowedDepositTokens.push(coin);
        }
        _modifyAllowances(type(uint).max);
    }

    /// @notice Deposits funds into the strategy
    /// @dev Only the vault contract can call this function
    /// @param _token The address of the token to deposit
    /// @param _user The address of the user making the deposit
    /// @param _minWant The minimum amount of want tokens to get from the curve deposit
    function deposit(
        address _token,
        address _user,
        uint256 _minWant
    ) external whenNotPaused onlyVault {
        require(allowedDepositTokens[_token].isAllowed, "TokenNotAllowed");
        uint256 wantBefore = balanceOfWant();
        _addLiquidityCurve(_token, _minWant);
        uint256 depositedWant = balanceOfWant() - wantBefore;
        userWantDeposit[_user] += depositedWant;
        totalWantDeposits += depositedWant;
        _addLiquidityConvex();
        emit Deposit(_user, _token, depositedWant);
    }

    /// @notice Withdraws funds from the strategy
    /// @dev Only the vault contract can call this function
    /// @param _user The address of the user making the withdrawal
    /// @param _amount The amount to withdraw
    /// @param _token The address of the token to withdraw
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve
    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        uint256 _minCurveOutput
    ) external onlyVault {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed, "TokenNotAllowed");
        uint256 wantBal = balanceOfWant();
        if (wantBal < _amount) {
            IConvexRewardPoolL1(rewardPool).withdrawAndUnwrap(_amount - wantBal, false);
            wantBal = balanceOfWant();
        }
        if (wantBal > _amount) wantBal = _amount;

        ICurveSwap(pool).remove_liquidity_one_coin(
            wantBal,
            int128(uint128(poolToken.index)),
            _minCurveOutput
        );
        // Subtracts to the user deposit
        uint256 tokenBal = _getTokenBalance(_token);
        uint256 _userDeposit = userWantDeposit[_user];
        userWantDeposit[_user] = 0;
        totalWantDeposits -= _userDeposit;
        // Calculates percentage of fees
        uint256 _rewards = 0;
        if (_userDeposit < wantBal) {
            uint256 rewardsPercentage = ((wantBal - _userDeposit) * 1e18) / wantBal;
            _rewards = (tokenBal * rewardsPercentage) / 1e18;
        }
        chargeFees(FeeType.PERFORMANCE, _token, _rewards);
        uint256 depositMinusRewards = tokenBal - _rewards;
        chargeFees(FeeType.MANAGEMENT, _token, depositMinusRewards);
        // Sends tokens
        uint256 withdrawAmount = _getTokenBalance(_token);
        IERC20Upgradeable(_token).safeTransfer(vault, withdrawAmount);
        emit Withdraw(_user, _token, withdrawAmount, balanceOf());
    }

    /// @notice Claims rewards for a user
    /// @dev Only the vault contract can call this function
    /// @param _user The address of the user claiming rewards
    /// @param _token The address of the token to receive rewards
    /// @param _amount The amount of tokens to claim as rewards
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve
    function claimRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _minCurveOutput
    ) external onlyVault {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed, "TokenNotAllowed");
        uint256 _userDeposit = userWantDeposit[_user];
        require(_userDeposit > 0, "InsufficientDeposit");
        require(_amount > _userDeposit, "ZeroRewards");
        uint256 rewardAmount = _amount - _userDeposit;
        uint256 wantBal = balanceOfWant();
        if (wantBal < rewardAmount) {
            IConvexRewardPoolL1(rewardPool).withdrawAndUnwrap(rewardAmount - wantBal, false);
            wantBal = balanceOfWant();
        }
        if (wantBal > rewardAmount) wantBal = rewardAmount;
        ICurveSwap(pool).remove_liquidity_one_coin(
            wantBal,
            int128(uint128(poolToken.index)),
            _minCurveOutput
        );
        uint256 totalRewards = _getTokenBalance(_token);
        chargeFees(FeeType.PERFORMANCE, _token, totalRewards);
        uint256 userRewards = _getTokenBalance(_token);
        IERC20Upgradeable(_token).safeTransfer(vault, userRewards);
        emit ClaimedRewards(_user, _token, userRewards, balanceOf());
    }

    /// @notice Harvests rewards without convex deposit
    function harvestOnDeposit() external whenNotPaused onlyVault {
        _harvest(false);
    }

    /// @notice Harvests earnings (compounds rewards) and charges performance fee
    function harvest() external {
        _harvest(true);
    }

    /// @notice Harvests earnings (compounds rewards) and charges performance fee
    function _harvest(bool _depositConvex) private {
        (, , , bool atLeastOneToHarvest) = getPendingToHarvest();
        if (!atLeastOneToHarvest) return;
        IConvexRewardPoolL1(rewardPool).getReward();
        address _depositToken = depositToken;
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            _exchangeAllToken(
                rewardTokens[i],
                _depositToken,
                calculations.getAutomaticSwapMin(rewardTokens[i], _depositToken)
            );
        }
        uint256 depositBal = _getTokenBalance(_depositToken);
        _addLiquidityCurve(_depositToken, calculations.getAutomaticCurveMinLp(depositBal));
        if (_depositConvex && !paused()) _addLiquidityConvex();
        lastHarvest = block.timestamp;
        emit Harvested(msg.sender, depositBal, balanceOf());
    }

    /// @notice Edits the "isAllowed" status of the deposit tokens
    /// @dev Only the admin and super admin can call this function
    /// @param _token The address of the token to edit
    /// @param _status The new status of the token (allowed=true or not allowed=false)
    function editAllowedDepositTokens(address _token, bool _status) external onlyAdmin {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed != _status, "TokenWontChange");
        require(ICurveSwap(pool).coins(poolToken.index) == _token, "TokenNotValid");
        allowedDepositTokens[_token].isAllowed = _status;
        // Excluded because it is needed to harvest (compound)
        if (depositToken != _token) {
            uint256 approvalAmount = _status ? type(uint).max : 0;
            IERC20Upgradeable(_token).safeApprove(pool, approvalAmount);
        }
        uint256 allowedLength = listAllowedDepositTokens.length;
        bool atLeastOne;
        for (uint256 i; i < allowedLength; i++) {
            if (allowedDepositTokens[listAllowedDepositTokens[i]].isAllowed) {
                atLeastOne = true;
                continue;
            }
        }
        require(atLeastOne, "CantDisableAllTokens");
        emit EditedAllowedTokens(_token, _status);
    }

    /// @notice Edits the minimum token harvest amounts
    /// @dev Only the admin and super admin can call this function
    /// @param _tokens An array of token addresses to edit
    /// @param _minAmounts An array of minimum harvest amounts corresponding to the tokens
    function editMinimumTokenHarvest(
        address[] calldata _tokens,
        uint256[] calldata _minAmounts
    ) external onlyAdmin {
        require(_tokens.length == _minAmounts.length, "LengthsMismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minimumToHarvest[_tokens[i]] = _minAmounts[i];
            emit MinimumToHarvestChanged(_tokens[i], _minAmounts[i]);
        }
    }

    /// @notice Sets the path for token swaps
    /// @dev Only the admin and super admin can call this function
    /// @param _from An array of source token addresses
    /// @param _to An array of target token addresses
    /// @param _path An array of encoded swap paths for each token pair
    function setPath(
        address[] calldata _from,
        address[] calldata _to,
        bytes[] calldata _path
    ) external onlyAdmin {
        uint256 inputsLength = _from.length;
        require(inputsLength == _to.length && inputsLength == _path.length, "LengthsMismatch");
        for (uint256 i = 0; i < inputsLength; i++) {
            paths[_from[i]][_to[i]] = _path[i];
            emit SetPath(_from[i], _to[i], _path[i]);
        }
    }

    /// @notice Sets the strategy calculations contract
    /// @dev Only the super admin can call this function
    /// @param _calculations The address of the strategy calculations contract
    function setStrategyCalculations(IStrategyCalculations _calculations) external onlySuperAdmin {
        require(address(_calculations) != address(0), "ZeroCalculations");
        calculations = _calculations;
    }

    /// @notice Sets the oracles for token price feeds
    /// @dev Only the super admin can call this function
    /// @param _oracles An array of Oracle structs containing token and oracle addresses
    function setOracles(Oracle[] calldata _oracles) external onlySuperAdmin {
        for (uint256 i; i < _oracles.length; i++) {
            require(_oracles[i].token != address(0), "ZeroOracleToken");
            require(_oracles[i].oracle != address(0), "ZeroOracleOracle");
            oracle[_oracles[i].token] = AggregatorV3Interface(_oracles[i].oracle);
            emit SetOracle(_oracles[i].token, _oracles[i].oracle);
        }
    }

    /// @notice Sets the default slippage for Curve swaps used during harvest
    /// @dev Only the admin and super admin can call this function
    /// @param _defaultSlippage The default slippage percentage (0-100)
    function setDefaultSlippageCurve(uint256 _defaultSlippage) external onlyAdmin {
        require(ONE_HUNDRED >= _defaultSlippage, "InvalidDefaultSlippage");
        emit SetSlippage(defaultSlippageCurve, _defaultSlippage, "Curve");
        defaultSlippageCurve = _defaultSlippage;
    }

    /// @notice Sets the default slippage for Uniswap swaps
    /// @dev Only the admin and super admin can call this function
    /// @param _defaultSlippage The default slippage percentage (0-100)
    function setDefaultSlippageUniswap(uint256 _defaultSlippage) external onlyAdmin {
        require(ONE_HUNDRED >= _defaultSlippage, "InvalidDefaultSlippage");
        emit SetSlippage(defaultSlippageUniswap, _defaultSlippage, "Uniswap");
        defaultSlippageUniswap = _defaultSlippage;
    }

    /// @notice Deletes the reward tokens array
    /// @dev Only the super admin can call this function
    function deleteRewards() external onlySuperAdmin {
        delete rewardTokens;
    }

    /// @notice Unpauses the contract deposits and increases the token allowances
    /// @dev Only the admin and super admin can call this function
    /// @dev This function also reactivates everything after a panic
    function unpause() external onlyAdmin {
        _unpause();
        _modifyAllowances(type(uint).max);
        _addLiquidityConvex();
        isPanicActive = false;
        emit PauseStatusChanged(false);
    }

    /// @notice Retrieves the reward tokens array
    /// @return An array of reward token addresses
    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    /// @notice Retrieves the allowed deposit tokens array
    /// @return An array of allowed deposit token addresses
    function getAllowedDepositTokens() external view returns (address[] memory) {
        return listAllowedDepositTokens;
    }

    /// @notice Pauses deposits, and withdraws all funds from the convex pool
    /// @dev Only the super admin can call this function
    /// @dev Users can still withdraw their deposit tokens
    function panic() public onlySuperAdmin {
        pause();
        isPanicActive = true;
        IConvexRewardPoolL1(rewardPool).withdrawAllAndUnwrap(false);
        emit PanicExecuted();
    }

    /// @notice Pauses deposits and modifies token allowances
    /// @dev Only the admin and super admin can call this function
    /// @dev Users can still withdraw their deposit tokens
    function pause() public onlyAdmin {
        _pause();
        _modifyAllowances(0);
        emit PauseStatusChanged(true);
    }

    /// @notice Adds reward tokens to the strategy
    /// @notice New reward tokens need to add an oracle and swap path to be reinvested
    /// @dev Only the super admin can call this function
    /// @param tokens An array of token addresses to add as reward tokens
    /// @param minAmounts An array of minimum harvest amounts corresponding to the reward tokens
    function addRewardToken(
        address[] calldata tokens,
        uint256[] calldata minAmounts
    ) public onlySuperAdmin {
        uint256 tokensLength = tokens.length;
        require(tokensLength == minAmounts.length, "LengthsMismatch");
        for (uint256 i; i < tokensLength; i++) {
            address token = tokens[i];
            require(token != address(0), "ZeroRewardToken");
            require(token != want, "CannotUseWant");
            require(token != rewardPool, "CannotUseRewardPool");
            uint256 rewardTokensLength = rewardTokens.length;
            for (uint256 j; j < rewardTokensLength; j++) {
                require(token != rewardTokens[j], "TokenAlreadyExists");
            }
            rewardTokens.push(token);
            minimumToHarvest[token] = minAmounts[i];
            IERC20Upgradeable(token).safeApprove(unirouterV3, 0);
            IERC20Upgradeable(token).safeApprove(unirouterV3, type(uint).max);
            emit AddedRewardToken(token, minAmounts[i]);
        }
    }

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return _rewardAmounts rewards the amount representing the pending rewards
    /// @return _rewardTokens addresses of the reward tokens
    /// @return _enoughRewards list indicating if the reward token is enough to harvest
    /// @return _atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvest()
        public
        view
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        )
    {
        return calculations.getPendingToHarvestView();
    }

    /// @notice Calculates the total balance of the strategy
    /// @return The total balance of the strategy
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    /// @notice Calculates the balance of the 'want' token held by the strategy
    /// @return The balance of the 'want' token
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Calculates the balance of the 'want' token in the convex pool
    /// @return The balance of the 'want' token in the convex pool
    function balanceOfPool() public view returns (uint256) {
        return IConvexRewardPoolL1(rewardPool).balanceOf(address(this));
    }

    /// @notice Charges fees (performance or management) in the specified token
    /// @param feeType The type of fee to charge (performance or management)
    /// @param token The token in which to charge the fees
    /// @param amount The amount of tokens to charge fees on
    function chargeFees(FeeType feeType, address token, uint256 amount) internal {
        (uint256 percentage, address feeRecipient) = feeType == FeeType.PERFORMANCE
            ? (performanceFee, performanceFeeRecipient)
            : (managementFee, managementFeeRecipient);
        if (percentage > 0) {
            uint256 feeAmount = (amount * percentage) / ONE_HUNDRED;
            IERC20Upgradeable(token).safeTransfer(feeRecipient, feeAmount);
            emit ChargedFees(feeType, feeAmount, feeRecipient);
        }
    }

    /// @notice Adds liquidity to the convex pool using the 'want' token
    /// @dev This function is private and used internally
    function _addLiquidityConvex() private {
        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            booster.deposit(pid, wantBal, true);
        }
    }

    /// @notice Adds liquidity to the Curve pool using the deposit token
    /// @param _minWant The minimum amount of 'want' tokens to obtain from the Curve pool
    /// @dev This function is private and used internally
    function _addLiquidityCurve(address _token, uint256 _minWant) private {
        uint256 depositAmount = _getTokenBalance(_token);
        uint256[2] memory amounts = calculations.getCurveAmounts(_token, depositAmount);
        if (paused()) IERC20Upgradeable(_token).safeApprove(pool, depositAmount);
        ICurveSwap(pool).add_liquidity(amounts, _minWant);
    }

    /// @notice Modifies token allowances for the strategy
    /// @param _amount The new allowance amount
    /// @dev This function is private and used internally
    function _modifyAllowances(uint256 _amount) private {
        IERC20Upgradeable(want).safeApprove(address(booster), _amount);
        address[] memory allowedTokens = listAllowedDepositTokens;
        uint256 tokensLength = allowedTokens.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20Upgradeable(allowedTokens[i]).safeApprove(pool, _amount);
        }
    }

    /// @notice Swaps all of the given token for another token
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _minSwap The minimum amount of tokens to receive from the swap
    /// @return amountOut The amount of tokens received from the swap
    /// @dev This function is private and used internally
    function _exchangeAllToken(
        address _from,
        address _to,
        uint256 _minSwap
    ) private returns (uint256 amountOut) {
        return _exchangeTokenAmount(_from, _to, _getTokenBalance(_from), _minSwap);
    }

    /// @notice Swaps the specified amount of tokens from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _minSwap The minimum amount of tokens to receive from the swap
    /// @return amountOut The amount of tokens received from the swap
    /// @dev This function is private and used internally
    function _exchangeTokenAmount(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minSwap
    ) private returns (uint256 amountOut) {
        if (_amount < minimumToHarvest[_from]) return 0;
        bytes memory path = paths[_from][_to];
        require(path.length > 0, "Nonexistent Path");
        return UniV3Actions.swapV3WithDeadline(unirouterV3, path, _amount, _minSwap);
    }

    /// @notice Retrieves the balance of the specified token held by the strategy
    /// @param _token The address of the token
    /// @return The balance of the token
    /// @dev This function is private and used internally
    function _getTokenBalance(address _token) private view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }
}
