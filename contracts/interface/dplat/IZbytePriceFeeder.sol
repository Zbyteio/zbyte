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
    /// @notice Event(0xec97c145) the equivalent Zbyte price for native ETH is set.
    event NativeEthEquivalentZbyteSet(uint256 nativeEthEquivalentZbyteInGwei);

    /// @notice Event(0xd12b5bd7) the Zbyte price in Gwei is set.
    event ZbytePriceInGweiSet(uint256 zbytePriceInGwei);

    /// @notice Event(0xabd3562e) the burn rate is set.
    event BurnRateInMillSet(uint256);

    /// @notice Converts eth to equivalent Zbyte amount.
    /// @dev Example:
    /// Say, Native Eth Price = 1$
    /// Zbyte Price = 2¢
    /// nativeEthEquivalentZbyteInGwei = 50,000,000,000 Gwei (i.e. 1 Native Eth = 50 Zbyte)
    /// ethAmount_  = 1,000,000,000,000,000,000 Wei (1 Native Eth)
    /// zbyteAmount = (1,000,000,000,000,000,000 * 50,000,000,000) / 1,000,000,000
    ///             = 50,000,000,000,000,000,000 Wei (50 ZBYT)
    /// @param ethAmount_ Amount of eth.
    /// @return Equivalent Amount of zbyte.
    function convertEthToEquivalentZbyte(uint256 ethAmount_) external view returns (uint256);

    /// @notice Converts price in millionths to Zbyte amount.
    /// @dev Example:
    /// Say, Unit Price = 1$
    /// Zbyte Price = 2¢
    /// So, zbytePriceEquivalentInGwei = 50,000,000,000 Gwei (i.e. 1 Unit = 50 Zbyte)
    /// priceInMill_ = 20 Mill (i.e. (2 / 1000) Unit)
    /// zbyteAmount = (20 * 50,000,000,000 * 1,000,000,000) / 1000
    ///             = 1,000,000,000,000,000,000 Wei (1 ZBYT)
    /// @param priceInMill_ Price in millionths.
    /// @return Equivalent Zbyte amount.
    function convertMillToZbyte(uint256 priceInMill_) external view returns (uint256);

    /// @notice DPlat fee in terms of Zbyte
    /// 1 Unit = 1000 Mill
    /// @return DPlat fee
    function getDPlatFeeInZbyte() external view returns(uint256);
}