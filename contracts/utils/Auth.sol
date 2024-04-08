// SPDX-License-Identifier: MIT

// --.. -... -.-- - . 
// ███████╗██████╗ ██╗   ██╗████████╗███████╗
// ╚══███╔╝██╔══██╗╚██╗ ██╔╝╚══██╔══╝██╔════╝
//   ███╔╝ ██████╔╝ ╚████╔╝    ██║   █████╗  
//  ███╔╝  ██╔══██╗  ╚██╔╝     ██║   ██╔══╝  
// ███████╗██████╔╝   ██║      ██║   ███████╗
// ╚══════╝╚═════╝    ╚═╝      ╚═╝   ╚══════╝
// --.. -... -.-- - . 
// Ref: https://github.com/transmissions11/solmate/tree/main/src/auth

pragma solidity ^0.8.9;

import "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Auth controls
/// @notice This abstract contract defines role-based access control (RBAC) mechanisms
/// to manage user roles and capabilities within a smart contract system.
abstract contract Auth {
    /// @notice Emitted when a user role is updated.
    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);
    /// @notice Emitted when a public capability is updated.
    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);
    /// @notice Emitted when a role capability is updated.
    event RoleCapabilityUpdated(uint8 indexed role, bytes4 indexed functionSig, bool enabled);

    struct DiamondStorage {
        mapping(address => bytes32) getUserRoles;
        mapping(bytes4 => bool) isCapabilityPublic;
        mapping(bytes4 => bytes32) getRolesWithCapability;
    }

    function diamondStorage() internal pure returns(DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.LibAuth.v1");
        assembly {
            ds.slot := storagePosition
        }
    }

    /// @notice Internal function to access the diamond storage.
    function getOwner() public virtual returns(address) {
    }

    /// @notice Checks if a user has a specific role.
    function doesUserHaveRole(address user, uint8 role) public view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return (uint256(ds.getUserRoles[user]) >> role) & 1 != 0;
    }

    /// @notice Checks if a role has access to a specific capability.
    function doesRoleHaveCapability(
        uint8 role,
        bytes4 functionSig
    ) public view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return (uint256(ds.getRolesWithCapability[functionSig]) >> role) & 1 != 0;
    }

    /// @notice Checks if a user can call a specific function.
    function canCall(
        address user,
        bytes4 functionSig
    ) public view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return
            ds.isCapabilityPublic[functionSig] ||
            bytes32(0) != ds.getUserRoles[user] & ds.getRolesWithCapability[functionSig];
    }

    /// @notice Checks if a user is authorized to call a specific function.
    function isAuthorized(address user, bytes4 functionSig) internal view returns (bool) {
        return canCall(user, functionSig);
    }

    /// @notice Checks if a user is authorized to call a specific function or is the owner.
    function isAuthorizedOrOwner(address user, bytes4 functionSig) internal returns (bool) {
        return canCall(user, functionSig) || user == getOwner();
    }

    /// @notice Modifier to require authentication for a function call.
    modifier requiresAuth {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");
        _;
    }

    /// @notice Modifier to require authentication or ownership for a function call.
    modifier requiresAuthOrOwner {
        require(isAuthorizedOrOwner(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    /// @notice Sets the public access status of a capability.
    function setPublicCapability(
        bytes4 functionSig,
        bool enabled
    ) public requiresAuthOrOwner {
        DiamondStorage storage ds = diamondStorage();
        ds.isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

    /// @notice Sets the access status of a capability for a specific role.
    function setRoleCapability(
        uint8 role,
        bytes4 functionSig,
        bool enabled
    ) public requiresAuthOrOwner {
        DiamondStorage storage ds = diamondStorage();
        if (enabled) {
            ds.getRolesWithCapability[functionSig] |= bytes32(1 << role);
        } else {
            ds.getRolesWithCapability[functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, functionSig, enabled);
    }

    /// @notice Sets the role of a user.
    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public requiresAuthOrOwner {
        DiamondStorage storage ds = diamondStorage();
        if (enabled) {
            ds.getUserRoles[user] |= bytes32(1 << role);
        } else {
            ds.getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}

/// @notice Abstract function to retrieve the owner address.
abstract contract AuthDiamond is Auth {
    function getOwner() public virtual override returns(address) {
        return LibDiamond.diamondStorage().contractOwner;
    }
}

/// @title Simple implementation of Auth with ownership delegated to an Ownable contract.
abstract contract AuthSimple is Auth, Ownable {
    function getOwner() public virtual override returns(address) {
        return owner();
    }
}