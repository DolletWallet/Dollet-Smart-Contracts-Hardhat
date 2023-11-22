// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { ISuperAdmin } from "../interfaces/dollet/IAdminStructure.sol";

/// @title Mock implementation of a Multisig
/// @dev This contract is used for testing purposes only and will not be used in production.
contract MultisigTest {
    ISuperAdmin public superAdmin;

    /// @dev Initializes the MultisigTest contract.
    /// @param _superAdmin The SuperAdmin contract address.
    constructor(address _superAdmin) {
        superAdmin = ISuperAdmin(_superAdmin);
    }

    /// @notice Executes acceptSuperAdmin() method on the SuperAdmin contract.
    function execute() external {
        superAdmin.acceptSuperAdmin();
    }
}
