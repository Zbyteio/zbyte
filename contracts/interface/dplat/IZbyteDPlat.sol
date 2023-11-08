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

interface IZbyteDPlat {
    function preExecute(address user_,
                        address dapp_,
                        bytes4 functionSig_,
                        uint256 chargeEth_) external returns(address);

    function postExecute(address payer_,
                         bool executeResult_,
                         uint256 reqValue_,
                         uint256 gasConsumedEth_,
                         uint256 preChargeEth_) external;
}