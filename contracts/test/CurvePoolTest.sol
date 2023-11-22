// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Mock contract of a curve pool
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
/// @notice This contract simulates the curve pool USDT/USDC
contract CurvePoolTest is ERC20 {
    using SafeERC20 for IERC20;

    /// @dev Array of coin addresses in the pool.
    address[] public coins;
    /// @dev Address of the owner of the contract.
    address public owner;
    /// @dev Percentage fee for withdrawals in basis points (0.01%).
    uint256 public percentage = 0.01 ether; // 0,01%
    /// @dev Constant for representing 100 (100%)
    uint256 public ONE_HUNDRED = 100 ether;
    /// @dev Represents the amount of coins per Curve LP token
    uint256[] private lpToCoinValue; // [coin0,coin1]
    /// @dev Represents the amount of Curve LP token per coin
    uint256[] private coinToLpValue; // [coin0,coin1]

    struct TokenPrice {
        address from;
        address to;
        uint256 price;
    }

    /// @dev Initializes the CurvePoolTest contract.
    /// @param _coins Array of coin addresses in the pool.
    constructor(
        address[] memory _coins,
        string memory _name,
        string memory _symbol,
        uint256[] memory _lpToCoinValue,
        uint256[] memory _coinToLpValue
    ) ERC20(_name, _symbol) {
        coins = _coins;
        owner = msg.sender;
        lpToCoinValue = _lpToCoinValue;
        coinToLpValue = _coinToLpValue;
    }

    /// @dev Edits the coin addresses in the pool.
    /// @param _coins Array of coin addresses in the pool.
    function editCoins(address[] memory _coins) external {
        coins = _coins;
    }

    /// @dev Edits the percentage fee for withdrawals.
    /// @param _percentage The new percentage fee.
    function editPercentage(uint256 _percentage) external {
        require(_percentage < ONE_HUNDRED, "InvalidPercentage");
        percentage = _percentage;
    }

    /// @dev Edits the lpToCoinValue.
    /// @param _lpToCoinValue The new lpToCoinValue.
    function editLpToCoinValue(uint256[2] memory _lpToCoinValue) external {
        lpToCoinValue = _lpToCoinValue;
    }

    /// @dev Edits the coinToLpValue.
    /// @param _coinToLpValue The new coinToLpValue.
    function editCoinToLpValue(uint256[2] memory _coinToLpValue) external {
        coinToLpValue = _coinToLpValue;
    }

    /// @dev Adds liquidity to the pool.
    /// @param amounts Array of token amounts to add liquidity.
    /// @param min_mint_amount Minimum mint amount expected.
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable {
        uint256 adjusted = calc_token_amount(amounts, true);
        uint256 amount = amounts[0] > 0 ? amounts[0] : amounts[1];
        address token = amounts[0] > 0 ? coins[0] : coins[1];
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        require(min_mint_amount <= adjusted, "ExcessiveMinMint");
        _mint(msg.sender, adjusted); //  Mints Curve LP
    }

    /// @dev Adds liquidity to the pool.
    /// @param amounts Array of token amounts to add liquidity.
    /// @param min_mint_amount Minimum mint amount expected.
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool
    ) external payable {
        uint256 adjusted = calc_token_amount(amounts, true);
        uint256 coinIndex;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) coinIndex = i;
        }
        uint256 amount = amounts[coinIndex];
        address token = coins[coinIndex];
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        require(min_mint_amount <= adjusted, "ExcessiveMinMint");
        _mint(msg.sender, adjusted); //  Mints Curve LP
    }

    /// @dev Returns the balance of tokens in the pool.
    /// @return balances Array of token balances in the pool.
    function balanceTokens() external view returns (uint256[] memory) {
        uint256 coinsLength = coins.length;
        uint256[] memory _balances = new uint256[](coinsLength);
        for (uint256 i; i < coinsLength; i++) {
            _balances[i] = balances(i);
        }
        return _balances;
    }

    /// @dev Returns the balance of tokens in the pool.
    /// @param _index index of the token
    /// @return balance balance to the token specified in the pool.
    function balances(uint256 _index) public view returns (uint256) {
        return IERC20(coins[_index]).balanceOf(address(this));
    }

    /// @dev Removes liquidity from the pool.
    /// @param token_amount The LP amount to withdraw
    /// @param i The index of the token to be removed.
    /// @param min_amount The minimum amount of tokens expected.
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) public {
        _burn(msg.sender, token_amount); // Burns Curve LP
        // Simulating the fee charged on withdrawals
        uint256 adjusted = calc_withdraw_one_coin(token_amount, i);
        require(min_amount <= adjusted, "ExcessiveMinAmount");
        address token = coins[uint256(uint128(i))];
        IERC20(token).safeTransfer(msg.sender, adjusted);
    }

    /// @dev Removes liquidity from the pool.
    /// @param token_amount The LP amount to withdraw
    /// @param i The index of the token to be removed.
    /// @param min_amount The minimum amount of tokens expected.
    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external {
        remove_liquidity_one_coin(token_amount, int128(uint128(i)), min_amount);
    }

    /// @dev Withdraws tokens from the pool.
    /// @param _coinIndex The index of the token to be withdrawn.
    /// @param _withdrawAll Flag indicating whether to withdraw all tokens.
    function withdrawTokens(uint256 _coinIndex, bool _withdrawAll) external {
        require(msg.sender == owner, "NotOwner");
        if (_withdrawAll) {
            for (uint256 i; i < coins.length; i++) {
                address currentCoin = coins[i];
                uint256 amount = IERC20(currentCoin).balanceOf(address(this));
                IERC20(currentCoin).safeTransfer(owner, amount);
            }
        } else {
            uint256 amount = IERC20(coins[_coinIndex]).balanceOf(address(this));
            IERC20(coins[_coinIndex]).safeTransfer(owner, amount);
        }
    }

    function setLPSupply(uint256 _supply) external {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > _supply) _burn(address(this), _totalSupply - _supply);
        else {
            _mint(address(this), _supply - _totalSupply);
        }
    }

    /// @dev Calculates the amount of tokens to be received on withdrawal.
    /// @param tokenAmount The LP amount to withdraw
    /// @param i The index of the token being withdrawn.
    /// @return adjusted The adjusted amount of tokens received.
    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) public view returns (uint256) {
        uint256 amount = tokenAmount - ((tokenAmount * percentage) / ONE_HUNDRED);
        address token = coins[uint256(uint128(i))];
        uint256 tokenDecimals = ERC20(token).decimals();
        uint256 adjusted = amount / (10 ** (18 - tokenDecimals));
        adjusted = (adjusted * lpToCoinValue[uint256(uint128(i))]) / 10 ** tokenDecimals;
        return adjusted;
    }

    /// @notice Calculates the amount of tokens to receive when withdrawing a single token from the CurveSwap contract
    /// @param tokenAmount The LP amount to withdraw
    /// @param i The index of the token in the pool
    /// @return The calculated amount of tokens to receive
    function calc_withdraw_one_coin(
        uint256 tokenAmount,
        uint256 i
    ) external view returns (uint256) {
        return calc_withdraw_one_coin(tokenAmount, int128(uint128(i)));
    }

    /// @dev Calculates the amount of Curve LP tokens to be minted.
    /// @param amounts Array of token amounts to be deposited.
    /// @return adjusted The adjusted amount of Curve LP tokens to be minted.
    function calc_token_amount(uint256[2] memory amounts, bool) public view returns (uint256) {
        require(amounts[0] == 0 || amounts[1] == 0, "MultipleTokensNotAllowed");
        uint256 coinIndex = amounts[0] > 0 ? 0 : 1;
        uint256 amount = amounts[coinIndex];
        address token = coins[coinIndex];
        uint256 adjusted = amount * (10 ** (18 - ERC20(token).decimals()));
        adjusted = (adjusted * coinToLpValue[coinIndex]) / 1e18;
        return adjusted;
    }

    /// @dev Calculates the amount of curve tokens to be minted.
    /// @param amounts Array of token amounts to be deposited.
    /// @return adjusted The adjusted amount of curve tokens to be minted.
    function calc_token_amount(uint256[3] memory amounts, bool) public view returns (uint256) {
        uint256 coinIndex;
        bool wasFound = false;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                require(!wasFound, "MultipleTokensNotAllowed");
                (coinIndex, wasFound) = (i, true);
            }
        }
        uint256 amount = amounts[coinIndex];
        address token = coins[coinIndex];
        uint256 adjusted = amount * (10 ** (18 - ERC20(token).decimals()));
        adjusted = (adjusted * coinToLpValue[coinIndex]) / 1e18;
        return adjusted;
    }

    /// @dev Returns lpToCoinValue.
    function getLpToCoinValues() external view returns (uint256[] memory) {
        return lpToCoinValue;
    }

    /// @dev Returns the virtual price of the pool.
    function getCoinToLpValues() external view returns (uint256[] memory) {
        return coinToLpValue;
    }

    /// @dev Returns the virtual price of the pool.
    /// @return The virtual price of the pool.
    function get_virtual_price() external pure returns (uint256) {
        // Harcoded value
        return 1012797248607140601;
    }
}
