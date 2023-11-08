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
abstract contract Auth {
    /* 
        //in the contract that imports LibAuth
        modifier requiresAuth {
            require(LibAuth.isAuthorized(user,fnSig) == true)
            _;
        }
        modifier requiresAuthOrOwner {
            require(msg.sender == owner || LibAuth.isAuthorized(user,fnSig))
            _;
        }

        transferOwnership() {
            should call LibAuth.setOwner(newOwner);
        }
    */

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);
    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);
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

    function getOwner() public virtual returns(address) {
    }

    function doesUserHaveRole(address user, uint8 role) public view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return (uint256(ds.getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        bytes4 functionSig
    ) public view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return (uint256(ds.getRolesWithCapability[functionSig]) >> role) & 1 != 0;
    }

    function canCall(
        address user,
        bytes4 functionSig
    ) public view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return
            ds.isCapabilityPublic[functionSig] ||
            bytes32(0) != ds.getUserRoles[user] & ds.getRolesWithCapability[functionSig];
    }

    function isAuthorized(address user, bytes4 functionSig) internal view returns (bool) {
        return canCall(user, functionSig);
    }

    function isAuthorizedOrOwner(address user, bytes4 functionSig) internal returns (bool) {
        return canCall(user, functionSig) || user == getOwner();
    }

    modifier requiresAuth {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");
        _;
    }

    modifier requiresAuthOrOwner {
        require(isAuthorizedOrOwner(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function setPublicCapability(
        bytes4 functionSig,
        bool enabled
    ) public requiresAuthOrOwner {
        DiamondStorage storage ds = diamondStorage();
        ds.isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

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

abstract contract AuthDiamond is Auth {
    function getOwner() public virtual override returns(address) {
        return LibDiamond.diamondStorage().contractOwner;
    }
}

abstract contract AuthSimple is Auth, Ownable {
    function getOwner() public virtual override returns(address) {
        return owner();
    }
}