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

/// @title Relay wrapper interface (facilitates cross chain call during deposit/mint)
interface IRelayWrapper {

    function performCrossChainCall(
        uint256 relay_,
        uint256 srcChain_,
        uint256 destChain_,
        address destContract_,
        bytes calldata destCallData_,
        bytes32 ack_,
        address callbackContract_,
        bytes calldata relayParams_
    ) external payable returns (bool);

    function isValidRelay(uint256 chainId, address relay_) external returns(bool);
    function updatePayload(uint256 destChain_,
                            address destContract_,
                            bytes32 ack_,
                            address callbackContract_,
                            bytes calldata data_) external pure returns(bytes memory);
}