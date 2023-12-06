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
    /// @notice event (0xf208822b): Zbyte authorized price modifiers registered.
    event ZbytePriceModifierRegistered(address,bool);


    error NotAuthorized(address);

    modifier onlyAuthorized() {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        if (!_dsb.authorizedPriceModifiers[_msgSender()]) revert NotAuthorized(_msgSender());
        _;
    }

    /// @notice Sets the address of the ZbyteVToken.
    /// @param zbyteVToken_ The address of the ZbyteVToken.
    function setZbyteVToken(address zbyteVToken_) public onlyOwner {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        _dsb.zbyteVToken = zbyteVToken_;
        emit ZbyteVTokenAddressSet(zbyteVToken_);
    }

    /// @notice Sets the Zbyte burn factor.
    /// @param zbyteBurnFactor_ Zbyte burn factor
    function setZbyteBurnFactor(uint256 zbyteBurnFactor_) public onlyOwner {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        _dsb.zbyteBurnFactor = zbyteBurnFactor_;
        emit ZbyteBurnFactorSet(zbyteBurnFactor_);
    }

    /// @notice Gets the address of the ZbyteVToken.
    /// @return The address of the ZbyteVToken.
    function getZbyteVToken() public view returns (address) {
        return LibDPlatBase._getZbyteVToken();
    }

    /// @notice Sets the value of Zbyte in native Ether (in Gwei).
    /// @param zbyteValueInNativeEthGwei_ The value of Zbyte in native Ether (in Gwei).
    function setZbyteValueInNativeEthGwei(uint256 zbyteValueInNativeEthGwei_) public onlyAuthorized {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        _dsb.zbyteValueInNativeEthGwei = zbyteValueInNativeEthGwei_;
        emit ZbyteValueInNativeEthGweiSet(zbyteValueInNativeEthGwei_);
    }


    /// @notice Registers authorized zbyte price modifiers.
    /// @param authorized_ Authorized price modifier's address.
    /// @param register_ register or deregister.
    function registerAuthorizedPriceModifiers(address authorized_, bool register_) public onlyOwner {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        _dsb.authorizedPriceModifiers[authorized_] = register_;
        emit ZbytePriceModifierRegistered(authorized_, register_);
    }

    /// @notice Gets the value of Zbyte in native Ether (in Gwei).
    /// @return The value of Zbyte in native Ether (in Gwei).
    function getZbyteValueInNativeEthGwei() public view returns (uint256) {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        return _dsb.zbyteValueInNativeEthGwei;
    }

    /// @notice Gets the Zbyte burn factor.
    /// @return The Zbyte burn factor (0-100).
    function getZbyteBurnFactor() public view returns (uint256) {
        return LibDPlatBase._getZbyteBurnFactor();
    }
}
