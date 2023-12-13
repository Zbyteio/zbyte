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

    /// @notice Returns equivalent amount of Zbyte to burn.
    /// @return Equivalent amount of Zbyte to burn.
    function getBurnAmountInZbyte() external view returns(uint256);
}