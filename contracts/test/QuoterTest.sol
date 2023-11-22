// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Path } from "./Path.sol";

/// @title Mock implementation for a uniswap quoter
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
contract QuoterTest {
    using Path for bytes;

    /// @dev Represents the percentage value of 1 ether (1%).
    uint256 public percentage = 1 ether; // 1%
    /// @dev Represents the value of 100 ether.
    uint256 public ONE_HUNDRED = 100 ether;
    /// @dev Represents the address of the contract owner.
    address public owner;

    /// @dev Stores the token price for each token pair.
    /// @dev tokenPrice[tokenA][tokenB] represents the price of tokenA in terms of tokenB.
    mapping(address => mapping(address => uint256)) public tokenPrice;

    struct TokenPrice {
        address from;
        address to;
        uint256 price;
    }

    /// @dev Initializes the QuoterTest contract.
    /// @param _prices The prices of the tokens.
    constructor(TokenPrice[] memory _prices) {
        owner = msg.sender;
        for (uint256 i; i < _prices.length; i++) {
            tokenPrice[_prices[i].from][_prices[i].to] = _prices[i].price;
        }
    }

    /// @dev Quotes the amount of output tokens given an exact input amount and a path of tokens.
    /// @param path The path of tokens to trade.
    /// @param amountIn The exact input amount.
    /// @return amountOut The amount of output tokens.
    function quoteExactInput(
        bytes calldata path,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        address[] memory route = pathToRoute(path);
        address fromToken = route[0];
        address toToken = route[route.length - 1];
        uint256 divisor = (10 ** ERC20(fromToken).decimals()) *
            10 ** (18 - ERC20(toToken).decimals());
        amountOut = (amountIn * tokenPrice[fromToken][toToken]) / divisor;
    }

    /// @dev Edits the percentage used for calculations.
    /// @param _percentage The new percentage value.
    function editPercentage(uint256 _percentage) external {
        require(_percentage < ONE_HUNDRED, "InvalidPercentage");
        percentage = _percentage;
    }

    /// @dev Converts a Path bytes array to a route array of tokens.
    /// @param _path The Path bytes array.
    /// @return route The array of tokens representing the route.
    function pathToRoute(bytes memory _path) public pure returns (address[] memory) {
        uint numPools = _path.numPools();
        address[] memory route = new address[](numPools + 1);
        for (uint i; i < numPools; i++) {
            (address tokenA, address tokenB, ) = _path.decodeFirstPool();
            route[i] = tokenA;
            route[i + 1] = tokenB;
            _path = _path.skipToken();
        }
        return route;
    }

    /// @dev Edits the token price between two tokens.
    /// @param _from The address of the token to trade from.
    /// @param _to The address of the token to trade to.
    /// @param _price The new token price.
    function editTokenPrice(address _from, address _to, uint256 _price) external {
        tokenPrice[_from][_to] = _price;
    }
}
