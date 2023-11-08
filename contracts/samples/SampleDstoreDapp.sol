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
import "@openzeppelin/contracts/access/Ownable.sol";

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