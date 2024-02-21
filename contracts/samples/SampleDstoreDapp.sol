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
/// @notice To prepare a contract for DPlat compatibility:
/// 1. Users are required to derive from the abstract\
/// contract called ZbyteContext.\
/// 2. Replace the msg.sender with _msgSender() and msg.data with _msgData().

contract SampleDstoreDapp is  ZbyteContext {
  event DStoreSet(address,uint256);

  // address of plat and creator of contract
  uint8 public storedValue;
  address public storedBy;

    constructor(address forwarder_) {
      _setTrustedForwarder(forwarder_);
    }
    
  function storeValue(uint8 _value) 
          public {

    storedBy = _msgSender();
    storedValue = _value;
    emit DStoreSet(storedBy, storedValue);
  }
}