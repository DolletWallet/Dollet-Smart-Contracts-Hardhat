// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Mock implementation of ERC20
/// @notice Simmulates an ERC20 contract
/// @dev This contract is used for testing purposes only and will not be used in production.
/// @dev The contract allows modifying different values without access control for ease of use.
contract ERC20Test is Ownable, ERC20 {
    using SafeERC20 for ERC20;
    uint8 private _decimals;

    /// @dev Initializes the ERC20Test contract.
    /// @param name_ The name of the ERC20 token.
    /// @param symbol_ The symbol of the ERC20 token.
    /// @param _supply The initial supply of the ERC20 token.
    /// @param decimals_ The number of decimal places for the ERC20 token.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _supply,
        uint8 decimals_
    ) ERC20(name_, symbol_) Ownable() {
        _decimals = decimals_;
        _mint(msg.sender, _supply);
    }

    /// @dev Mints new tokens and assigns them to the specified user.
    /// @param user The address of the user to whom the tokens will be minted.
    /// @param amount The amount of tokens to mint.
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }

    /// @dev Burns tokens from the specified user.
    /// @param user The address of the user from whom the tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address user, uint256 amount) external onlyOwner {
        _burn(user, amount);
    }

    /// @dev Edits the number of decimal places for the ERC20 token.
    /// @param decimals_ The new number of decimal places.
    function editDecimals(uint8 decimals_) external onlyOwner {
        _decimals = decimals_;
    }

    /// @dev Returns the number of decimal places for the ERC20 token.
    /// @return The number of decimal places.
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
