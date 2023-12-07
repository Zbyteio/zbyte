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
import "../../interface/dplat/IEnterprisePaymentPolicy.sol";
import "../../interface/dplat/IZbytePriceFeeder.sol";
import "../ZbyteVToken.sol";

/// @title Zbyte DPlat Payment Facet
contract ZbyteDPlatPaymentFacet is ZbyteContextDiamond {

    /// events
    /// @notice Error(0x187e1a0c) Amount to be refund in terms of Eth to Payer.
    event RefundEthToPayer(address,uint256);

    /// @notice Determines the payer for a transaction.
    /// @param user_ The user's address.
    /// @param dapp_ The Dapp's address.
    /// @param functionSig_ The function signature (bytes4).
    /// @param amount_ The transaction amount.
    /// @return The payer's address.
    function getPayer(address user_, address dapp_, bytes4 functionSig_, uint256 amount_) public view returns (bytes4, uint256, address) {
        bytes4 _dappEnterprise = LibDPlatRegistration.isEnterpriseDappRegistered(dapp_);

        if (_dappEnterprise != bytes4(0)) {
            address _enterpriseProvider = LibDPlatRegistration.isEnterpriseRegistered(_dappEnterprise);
            if (_enterpriseProvider != address(0) && LibDPlatRegistration.isProviderRegistered(_enterpriseProvider)) {
                uint256 _enterpriseLimit = LibDPlatRegistration._getEnterpriseLimit(_dappEnterprise);
                address _enterprisePolicy = LibDPlatRegistration._doesEnterpriseHavePolicy(_dappEnterprise);

                if (_enterpriseLimit > amount_) {
                    if (_enterprisePolicy != address(0)) {
                        bool _willEnterprisePay = IEnterprisePaymentPolicy(_enterprisePolicy).isUserOrDappEligibleForPayment(user_, dapp_, functionSig_, amount_);
                        if (_willEnterprisePay) {
                            return (_dappEnterprise, _enterpriseLimit, _enterpriseProvider);
                        }
                    } else {
                        return (_dappEnterprise, _enterpriseLimit, _enterpriseProvider);

                    }
                }
            }
        }

        bytes4 _userEnterprise = LibDPlatRegistration.isEnterpriseUserRegistered(user_);
        if (_userEnterprise != bytes4(0) && _userEnterprise != _dappEnterprise) {

            address _enterpriseProvider = LibDPlatRegistration.isEnterpriseRegistered(_userEnterprise); 
            if (_enterpriseProvider != address(0) && LibDPlatRegistration.isProviderRegistered(_enterpriseProvider)) {

                uint256 _enterpriseLimit = LibDPlatRegistration._getEnterpriseLimit(_userEnterprise);
                address _enterprisePolicy = LibDPlatRegistration._doesEnterpriseHavePolicy(_userEnterprise);

                if (_enterpriseLimit > amount_) {
                    if (_enterprisePolicy != address(0)) {
                        bool _willEnterprisePay = IEnterprisePaymentPolicy(_enterprisePolicy).isUserOrDappEligibleForPayment(user_, dapp_, functionSig_, amount_);
                        if (_willEnterprisePay) {
                            return (_userEnterprise, _enterpriseLimit, _enterpriseProvider);
                        }
                    } else {
                        return (_userEnterprise, _enterpriseLimit, _enterpriseProvider);
                    }
                }
            }
        }
        return (bytes4(0), uint256(0), user_);
    }

    /// @notice Pre Execution (Finds the payer and charges in ZbyteVToken)
    /// @param dapp_ The Dapp's address.
    /// @param user_ The user's address.
    /// @param functionSig_ The function signature (bytes4).
    /// @param ethChargeAmount_ The Ether amount to charge.
    function preExecute(
        address dapp_,
        address user_,
        bytes4 functionSig_,
        uint256 ethChargeAmount_
    ) public onlyForwarder returns(address) {
        bytes4 _payerEnterprise;
        uint256 _currentEnterpriseLimit;
        address _payer;
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        uint256 _zbyteCharge = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(ethChargeAmount_);
        (_payerEnterprise, _currentEnterpriseLimit, _payer) = getPayer(user_, dapp_, functionSig_, _zbyteCharge);

        if(_payerEnterprise != bytes4(0)) {
            address _enterprisePolicy = LibDPlatRegistration._doesEnterpriseHavePolicy(_payerEnterprise);
            if(_enterprisePolicy != address(0)) {
                IEnterprisePaymentPolicy(_enterprisePolicy).updateEnterpriseEligibility(user_, dapp_, functionSig_, _zbyteCharge);
            }
            LibDPlatRegistration._setEntepriseLimit(_payerEnterprise, _currentEnterpriseLimit - _zbyteCharge);
        }
        return _payer;
    }


    /// @dev Executes a transaction and handles Zbyte-related operations.
    ///
    /// @param payer_ The address of the payer initiating the execution.
    /// @param executeResult_ A boolean indicating the success of the execution.
    /// @param reqValue_ The amount of Ether sent with the execution request.
    /// @param gasConsumedEth_ The amount of Ether consumed for gas during execution.
    /// @param preChargeEth_ The amount of Ether charged before execution.
    ///
    /// This function can only be called by the `onlyForwarder` modifier.
    function postExecute(address payer_,
                         bool executeResult_,
                         uint256 reqValue_,
                         uint256 gasConsumedEth_,
                         uint256 preChargeEth_) public onlyForwarder {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        uint256 _zbyteBurn = IZbytePriceFeeder(_dsb.zbytePriceFeeder).getBurnAmountInZbyte();

        // Execute was successfull, also consider eth sent to execute request
        if (executeResult_) {
            gasConsumedEth_ += reqValue_;
        }       
        uint256 _chargeEth = gasConsumedEth_ > preChargeEth_ ? gasConsumedEth_ - preChargeEth_ : 0;
        uint256 _refundEth = gasConsumedEth_ > preChargeEth_ ? 0 : preChargeEth_ - gasConsumedEth_;

        uint256 _zbyteCharge = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(_chargeEth);

        address _vZbyte = LibDPlatBase._getZbyteVToken();
        if(_zbyteCharge != 0)
            ZbyteVToken(payable(_vZbyte)).transferFrom(payer_, msg.sender, _zbyteCharge);
        if(_zbyteBurn != 0)
            ZbyteVToken(payable(_vZbyte)).burn(payer_, _zbyteBurn);

        emit RefundEthToPayer(payer_, _refundEth);
    }
}
