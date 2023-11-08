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

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title The ZBYT ERC20 contract
/// @dev ERC2771Context with a function to set forwarder
abstract contract ZbyteContext is Context, Ownable {
    // errors
    /// @notice error (0xbf064619): Contract cannot receive ether
    error CannotSendEther();
    /// @notice error (0xd92e233d): Address is address(0)
    error ZeroAddress();
    /// @notice error(): Value sent is 0
    error ZeroValue();

    // events
    /// @notice event (0x94aed472): Forwarder address is changed
    event ForwarderSet(address,address);

    // Trusted forwarder address
    address private trustedForwarder;

    // /// @notice ZbyteContext constructor
    // /// @param forwarder_ Forwarder contact address
    // constructor(address forwarder_) {
    //     _setTrustedForwarder(forwarder_);
    // }

    /// @notice Check if the given address is the trusted forwarder
    /// @param forwarder_ Address to check
    /// @return true if forwarder_ is trusted forwarder
    function isTrustedForwarder(address forwarder_) public view virtual returns (bool) {
        return forwarder_ == trustedForwarder;
    }

    /// @notice Set a trusted forwarder address
    /// @param forwarder_ Trusted forwarder address
    /// @dev emits ForwarderSet on success
    function _setTrustedForwarder(address forwarder_) internal {
        if (forwarder_ == address(0)) {
            revert ZeroAddress();
        }
        address oldForwarder = trustedForwarder;
        trustedForwarder = forwarder_;

        emit ForwarderSet(oldForwarder,forwarder_);
    }

    /// @notice Set the forwarder contract address
    /// @param forwarder_ Frwarder conract address
    /// @dev onlyOwner can call
    function setTrustedForwarder(address forwarder_) public onlyOwner {
        _setTrustedForwarder(forwarder_);
    }

    /// @notice Extract true caller if called via trusted forwarder
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    /// @notice Extract data if called via trusted forwarder
    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}
