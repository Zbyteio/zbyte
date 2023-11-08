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
import "./LibZbyteForwarderFacet.sol";

contract ZbyteForwarderFacet {
    // events
    /// @notice event (0x94aed472): Forwarder address is changed
    event ForwarderSet(address);

    /// @notice Set the address of trusted forwarder
    /// @param forwarder_ Address of the trusted forwarder
    function setForwarder(address forwarder_) public {
        LibZbyteForwarderFacet._setTrustedForwarder(forwarder_);
        emit ForwarderSet(forwarder_);
    }

    /// @notice Get the address of trusted forwarder
    function getTrustedForwarder() public view returns(address) {
        return LibZbyteForwarderFacet._getTrustedForwarder();
    }
}