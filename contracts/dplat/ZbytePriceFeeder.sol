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
import "../interface/dplat/IZbytePriceFeeder.sol";
import "../utils/ZbyteContext.sol";


/// @title ZbytePriceFeeder
/// @notice Implements the IZbytePriceFeeder interface and provides functionality to manage gas costs and price conversions.
contract ZbytePriceFeeder is IZbytePriceFeeder, ZbyteContext {
    // Gas cost data storage
    mapping(uint256 => mapping(uint256 => uint256)) approveAndDepositGasCostInZbyte;
    // Conversion factors
    uint256 nativeEthEquivalentZbyteInGwei;
    uint256 zbytePriceEquivalentInGwei;
    uint256 burnRateInMill;

    constructor(address forwarder_) {
        _setTrustedForwarder(forwarder_);
    }

    /// @notice Sets the equivalent Zbyte price in Gwei for native ETH.
    /// @param nativeEthEquivalentZbyteInGwei_ The equivalent Zbyte price in Gwei for native ETH.
    function setNativeEthEquivalentZbyteInGwei(uint256 nativeEthEquivalentZbyteInGwei_) public onlyOwner {
        nativeEthEquivalentZbyteInGwei = nativeEthEquivalentZbyteInGwei_;
        emit NativeEthEquivalentZbyteSet(nativeEthEquivalentZbyteInGwei_);
    }

    /// @notice Sets the Zbyte price in Gwei.
    /// @param zbytePriceInGwei_ The Zbyte price in Gwei.
    function setZbytePriceInGwei(uint256 zbytePriceInGwei_) public onlyOwner {
        zbytePriceEquivalentInGwei = zbytePriceInGwei_;
        emit ZbytePriceInGweiSet(zbytePriceInGwei_);
    }

    /// @notice Converts eth to equivalent Zbyte amount.
    /// @param ethAmount_ Amount of eth.
    /// @return Equivalent Amount of zbyte.
    function convertEthToEquivalentZbyte(uint256 ethAmount_) public view returns (uint256) {
        uint256 _zbyteAmount = (ethAmount_ * nativeEthEquivalentZbyteInGwei) / 10**9;
        return _zbyteAmount;
    }

    /// @notice Converts price in millionths to Zbyte amount.
    /// @param priceInMill_ Price in millionths.
    /// @return Equivalent Zbyte amount.
    function convertMillToZbyte(uint256 priceInMill_) public view returns (uint256) {
        return (priceInMill_ * zbytePriceEquivalentInGwei * 10**9) / 1000;
    }

    /// @notice Returns equivalent amount of Zbyte to burn.
    /// @return Equivalent amount of Zbyte to burn.
    function getBurnAmountInZbyte() public view returns(uint256) {
        return convertMillToZbyte(burnRateInMill);
    }

    /// @notice Sets the gas cost for approve and deposit operation.
    /// @param relay_ The relay identifier.
    /// @param remoteChainId_ The remote chain identifier.
    /// @param gasCostInZbyte_ Gas cost in Zbyte.
    function setApproveAndDepositGasCost(uint256 relay_, uint256 remoteChainId_, uint256 gasCostInZbyte_) public onlyOwner {
        approveAndDepositGasCostInZbyte[relay_][remoteChainId_] = gasCostInZbyte_;
        emit ApproveAndDepositGasCostSet(relay_, remoteChainId_, gasCostInZbyte_);
    }

    /// @notice Retrieves the gas cost for approve and deposit operation converted to Zbyte.
    /// @param relay_ The relay identifier.
    /// @param remoteChainId_ The remote chain identifier.
    /// @return Equivalent Zbyte gas cost.
    function getApproveAndDepositGasCostInZbyte(uint256 relay_, uint256 remoteChainId_) public view returns (uint256) {
        return approveAndDepositGasCostInZbyte[relay_][remoteChainId_];
    }

    /// @notice Sets burn rate for invoke calls in mill
    /// @param burnRate_ burn rate in mill
    function setBurnRateInMill(uint256 burnRate_) public onlyOwner {
        burnRateInMill = burnRate_;
        emit BurnRateInMillSet(burnRate_);
    } 
}