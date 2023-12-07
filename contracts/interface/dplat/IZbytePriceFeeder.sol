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

/// @title IZbytePriceFeeder
/// @notice Interface for Zbyte price feeder, defining functions for gas cost conversion and retrieval.
interface IZbytePriceFeeder {
    /// @notice Event emitted when the equivalent Zbyte price for native ETH is set.
    event NativeEthEquivalentZbyteSet(uint256 nativeEthEquivalentZbyteInGwei);

    /// @notice Event emitted when the Zbyte price in Gwei is set.
    event ZbytePriceInGweiSet(uint256 zbytePriceInGwei);

    /// @notice Event emitted when the gas cost for approve and deposit operation is set.
    event ApproveAndDepositGasCostSet(uint256 relay, uint256 remoteChainId, uint256 gasCost);

    /// @notice Event emitted when the burn rate is set.
    event BurnRateInMillSet(uint256);

    /// @notice Converts eth to equivalent Zbyte amount.
    /// @param ethAmount_ Amount of eth.
    /// @return Equivalent Amount of zbyte.
    function convertEthToEquivalentZbyte(uint256 ethAmount_) external view returns (uint256);

    /// @notice Converts price in millionths to Zbyte amount.
    /// @param priceInMill_ Price in millionths.
    /// @return Equivalent Zbyte amount.
    function convertMillToZbyte(uint256 priceInMill_) external view returns (uint256);

    /// @notice Retrieves the gas cost for approve and deposit operation converted to Zbyte.
    /// @param relay_ The relay identifier.
    /// @param remoteChainId_ The remote chain identifier.
    /// @return Equivalent Zbyte gas cost.
    function getApproveAndDepositGasCostInZbyte(uint256 relay_, uint256 remoteChainId_) external view returns (uint256);

    /// @notice Returns equivalent amount of Zbyte to burn.
    /// @return Equivalent amount of Zbyte to burn.
    function getBurnAmountInZbyte() external view returns(uint256);
}