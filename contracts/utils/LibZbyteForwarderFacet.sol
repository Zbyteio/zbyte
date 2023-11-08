// SPDX-License-Identifier: MIT

// --.. -... -.-- - . 
// ███████╗██████╗ ██╗   ██╗████████╗███████╗
// ╚══███╔╝██╔══██╗╚██╗ ██╔╝╚══██╔══╝██╔════╝
//   ███╔╝ ██████╔╝ ╚████╔╝    ██║   █████╗  
//  ███╔╝  ██╔══██╗  ╚██╔╝     ██║   ██╔══╝  
// ███████╗██████╔╝   ██║      ██║   ███████╗
// ╚══════╝╚═════╝    ╚═╝      ╚═╝   ╚══════╝
// --.. -... -.-- - . 

pragma solidity ^0.8.9;
import "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";

/// @notice The Zbyte Forwarder Facet
/// @dev The Zbyte Forwarder Facet
library LibZbyteForwarderFacet {

    /// @notice Diamond storage for DPlat registration struct
    struct DiamondStorage {
        address trustedForwarder;
    }

    /// @notice Retrieves the DiamondStorage struct for the library.
    /// @dev trustedForwarder: Address of the trusted forwarder
    function diamondStorage() internal pure returns(DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.LibZbyteForwarderFacet.v1");
        assembly {
            ds.slot := storagePosition
        }
    }

    /// @notice Sets the address of trusted forwarder
    /// @param forwarder_: Address of the trusted forwarder
    function _setTrustedForwarder(address forwarder_) internal {
        LibDiamond.enforceIsContractOwner();
        DiamondStorage storage dsc = diamondStorage();
        dsc.trustedForwarder = forwarder_;
    }

    /// @notice Gets the address of trusted forwarder
    function _getTrustedForwarder() internal view returns(address) {
        DiamondStorage storage dsc = diamondStorage();
        return dsc.trustedForwarder;
    }

    /// @notice Checks if the given forwarder is the trusted forwarder
    /// @param forwarder_: Address of the forwarder to check
    function isTrustedForwarder(address forwarder_) internal view returns(bool) {
        DiamondStorage storage dsc = diamondStorage();
        return forwarder_ == dsc.trustedForwarder;
    }
}