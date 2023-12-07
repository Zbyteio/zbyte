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

import "./LibDPlat.sol";
import "../../utils/ZbyteContextDiamond.sol";

/// @title DPlat Base Facet contract
/// @dev DPlat Base Facet contract
contract ZbyteDPlatBaseFacet is ZbyteContextDiamond {

    // events
    /// @notice event (0x10e1dc22): VZbyte token address is set.
    event ZbyteVTokenAddressSet(address);
    /// @notice event (0xa0e61546): Zbyte token value in terms of native eth is set.
    event ZbyteValueInNativeEthGweiSet(uint256);
    /// @notice event (0xd7a7cf8c): Zbyte burn factor is set.
    event ZbyteBurnFactorSet(uint256);
    /// @notice event (0xe603ec36): Zbyte price feeder is set.
    event ZbytePriceFeederSet(address);

    /// @notice Sets the address of the ZbyteVToken.
    /// @param zbyteVToken_ The address of the ZbyteVToken.
    function setZbyteVToken(address zbyteVToken_) public onlyOwner {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        _dsb.zbyteVToken = zbyteVToken_;
        emit ZbyteVTokenAddressSet(zbyteVToken_);
    }

    /// @notice Sets the Zbyte Price Feeder address.
    /// @param zbytePriceFeeder_ Zbyte Price Feeder address.
    function setZbytePriceFeeder(address zbytePriceFeeder_) public onlyOwner {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        _dsb.zbytePriceFeeder = zbytePriceFeeder_;
        emit ZbytePriceFeederSet(zbytePriceFeeder_);
    }

    /// @notice Gets the address of the ZbyteVToken.
    /// @return The address of the ZbyteVToken.
    function getZbyteVToken() public view returns (address) {
        return LibDPlatBase._getZbyteVToken();
    }

    function getZbytePriceFeeder() public view returns (address) {
        return LibDPlatBase._getZbytePriceFeeder();
    }
}
