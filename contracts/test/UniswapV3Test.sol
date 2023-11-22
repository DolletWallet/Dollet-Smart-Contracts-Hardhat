// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Path } from "./Path.sol";

/// @title Mock implementation of UniswapV3
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// The contract allows modifying different values without access control just for ease of use.
contract UniswapV3Test {
    using Path for bytes;
    using SafeERC20 for IERC20;

    /// @notice Address of the owner
    address public owner;
    /// @notice Address of crv contract
    address public crv;
    /// @notice Address of cvx contract
    address public cvx;
    /// @notice Address of usdc contract
    address public usdc;
    /// @notice Address of usdt contract
    address public usdt;

    /// @dev tokenPrice[tokenA][tokenB] represents the price of tokenA in terms of tokenB.
    mapping(address => mapping(address => uint256)) public tokenPrice;

    /// @notice struct for inputs used when doing a swap.
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct TokenPrice {
        address from;
        address to;
        uint256 price;
    }

    /// @notice Allows to initialize the values of this uniswap contract
    /// @param _crv Address of crv contract
    /// @param _cvx Address of cvx contract
    /// @param _usdc Address of usdc contract
    /// @param _usdt Address of usdt contract
    constructor(
        address _crv,
        address _cvx,
        address _usdc,
        address _usdt,
        TokenPrice[] memory _prices
    ) {
        owner = msg.sender;
        crv = _crv;
        cvx = _cvx;
        usdc = _usdc;
        usdt = _usdt;
        for (uint256 i; i < _prices.length; i++) {
            tokenPrice[_prices[i].from][_prices[i].to] = _prices[i].price;
        }
    }

    /// @dev Performs an exact input swap.
    /// @param params The swap parameters including path, recipient, deadline, amountIn, and amountOutMinimum.
    /// @return amountOut The amount of output tokens received from the swap.
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut) {
        address[] memory route = pathToRoute(params.path);
        address fromToken = route[0];
        address toToken = route[route.length - 1];
        uint256 divisor = (10 ** ERC20(fromToken).decimals()) *
            10 ** (18 - ERC20(toToken).decimals());
        amountOut = (params.amountIn * tokenPrice[fromToken][toToken]) / divisor;
        require(params.amountOutMinimum <= amountOut, "ExcessiveAmountOut");
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), params.amountIn);
        IERC20(toToken).safeTransfer(msg.sender, amountOut);
    }

    /// @dev Withdraws tokens from the contract.
    /// @param _tokens The tokens to withdraw.
    function withdrawTokens(address[] calldata _tokens) external {
        require(msg.sender == owner, "NotOwner");
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 amount = IERC20(_tokens[i]).balanceOf(address(this));
            IERC20(_tokens[i]).safeTransfer(owner, amount);
        }
    }

    /// @dev Converts a path to a route of tokens.
    /// @param _path The path of tokens.
    /// @return route The route of tokens.
    function pathToRoute(bytes memory _path) public pure returns (address[] memory) {
        uint256 numPools = _path.numPools();
        address[] memory route = new address[](numPools + 1);
        for (uint i; i < numPools; i++) {
            (address tokenA, address tokenB, ) = _path.decodeFirstPool();
            route[i] = tokenA;
            route[i + 1] = tokenB;
            _path = _path.skipToken();
        }
        return route;
    }

    /// @dev Edits the CRV token address.
    /// @param _crv The new CRV token address.
    function editCRV(address _crv) external {
        crv = _crv;
    }

    /// @dev Edits the USDC token address.
    /// @param _usdc The new USDC token address.
    function editUSDC(address _usdc) external {
        usdc = _usdc;
    }

    /// @dev Edits the USDT token address.
    /// @param _usdt The new USDT token address.
    function editUSDT(address _usdt) external {
        usdt = _usdt;
    }

    /// @dev Edits the token price for a given pair of tokens.
    /// @param _from The token to convert from.
    /// @param _to The token to convert to.
    /// @param _price The new token price.
    function editTokenPrice(address _from, address _to, uint256 _price) external {
        tokenPrice[_from][_to] = _price;
    }

    /// @dev Retrieves the balances of the contract for CRV, USDC, and USDT tokens.
    /// @return balances The balances of CRV, USDC, and USDT tokens.
    /// @return tokens The addresses of CRV, USDC, and USDT tokens.
    function getBalances() external view returns (uint256[] memory, address[] memory) {
        uint256[] memory balances = new uint256[](3);
        address[] memory tokens = new address[](3);
        balances[0] = IERC20(crv).balanceOf(address(this));
        balances[1] = IERC20(usdc).balanceOf(address(this));
        balances[2] = IERC20(usdt).balanceOf(address(this));
        tokens[0] = crv;
        tokens[1] = usdc;
        tokens[2] = usdt;
        return (balances, tokens);
    }
}
