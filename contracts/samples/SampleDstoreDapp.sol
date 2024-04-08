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

import "../utils/ZbyteContext.sol";

/// @title Sample Data Storage Dapp
/// @notice This contract serves as a sample data storage decentralized application (DApp).
/// It allows users to store a uint8 value along with the address of the entity performing the storage operation.
/// To prepare a contract for DPlat compatibility:
/// 1. Users are required to derive from the abstract contract called ZbyteContext.
/// 2. Replace the usage of msg.sender with _msgSender() and msg.data with _msgData().

contract SampleDstoreDapp is  ZbyteContext {
  /// @dev Emitted when a value is stored.
  event DStoreSet(address,uint256);
  /// @notice Stored uint8 value
  uint8 public storedValue;
  /// @notice Address of the entity that stored the value
  address public storedBy;

    /// @notice Constructor to set the trusted forwarder
    /// @param forwarder_ The address of the trusted forwarder
    constructor(address forwarder_) {
      _setTrustedForwarder(forwarder_);
    }

    /// @notice Function to store a uint8 value
    /// @param _value The uint8 value to be stored
  function storeValue(uint8 _value) 
          public {

    storedBy = _msgSender();
    storedValue = _value;
    emit DStoreSet(storedBy, storedValue);
  }
}
