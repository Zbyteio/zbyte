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

interface IEnterprisePaymentPolicy {
    function isUserOrDappEligibleForPayment(address user_, address dapp_, bytes4 functionSig_, uint256 amount_) external view returns(bool);
    function updateEnterpriseEligibility(address user_, address dapp_, bytes4 functionSig_, uint256 amount_) external returns(bool);}