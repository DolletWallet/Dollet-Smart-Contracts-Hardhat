// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { DolletVaultTricryptoNativeL1 } from "../vaults/DolletVaultTricryptoNativeL1.sol";
import { DolletVault } from "../vaults/DolletVault.sol";

/// @title Mock implementation of a Vault
/// @dev This contract is used for testing purposes only, it won't be used for production.
/// @dev The contract allows to modifiy different values without access control just for ease of use
/// @notice This contract it is used to simulate a function to mint LP
contract VaultMock is DolletVault {
    /// @dev Allows anyone to mint vault LP to simulated some actions for testing
    /// @param _user Address of the user that receives the LPs
    /// @param _amount Amount of LPs to be minted
    function mintLP(address _user, uint256 _amount) external {
        _mint(_user, _amount);
    }
}

contract VaultMockEth is DolletVaultTricryptoNativeL1 {
    /// @dev Allows anyone to mint vault LP to simulated some actions for testing
    /// @param _user Address of the user that receives the LPs
    /// @param _amount Amount of LPs to be minted
    function mintLP(address _user, uint256 _amount) external {
        _mint(_user, _amount);
    }
}
