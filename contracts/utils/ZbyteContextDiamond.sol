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

contract ZbyteContextDiamond {
    /// @notice error (0x5ac85bab): Caller is not a forwarder
    error NotAForwarder();

    /// @notice modifier to enforce that the caller is the owner
    modifier onlyOwner {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /// @notice modifier to enforce that the caller is the forwarder
    modifier onlyForwarder {
        if(LibZbyteForwarderFacet.isTrustedForwarder(_msgSender())) revert NotAForwarder();
        _;
    }

    /// @notice Extract true caller if called via trusted forwarder
    function _msgSender() internal view returns (address ret) {
        if (msg.data.length >= 20 && LibZbyteForwarderFacet.isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @notice Extract data if called via trusted forwarder
    function _msgData() internal view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && LibZbyteForwarderFacet.isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}