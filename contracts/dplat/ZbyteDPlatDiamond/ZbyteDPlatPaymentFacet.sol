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
    /// @notice Event(0x306f3bdb) Address of the payer, DPlat, Infra and Royalty Fee
    event ExecuteFees(address,uint256,uint256,uint256);
    error GetRoyaltyFeeInZbyteFailed(bytes);

    /// @notice Determines the payer for a transaction.
    /// @notice In the absence of an enteprise policy, if a dapp or user is registered with ent,
    /// ent will pay for the call, as long as it has balance
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
                        //In absence of an ent policy, if a dapp is registered with ent
                        //ent will pay for any call to that dapp, as long as it has balance
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
                        //In absence of an ent policy, if a user is registered with ent
                        //ent will pay for any call from that user, as long as it has balance
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

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 functionSelector = bytes4(keccak256("getRoyaltFeeInZbyte(address,address,bytes4,address,uint256)"));
        LibDiamond.FacetAddressAndPosition memory _facetAddressAndPosition = ds.selectorToFacetAndPosition[functionSelector];
        bytes memory getRoyaltFeeInZbyteCall = abi.encodeWithSelector(functionSelector, dapp_,user_,functionSig_,_payer,_zbyteCharge);
        (bool _success, bytes memory _result) = address(_facetAddressAndPosition.facetAddress).delegatecall(getRoyaltFeeInZbyteCall);

        if(_success) {
            (uint256 _royaltyFee, address _royaltyReceiver, address _royaltyPayer) = abi.decode(_result, (uint256,address,address));
            if(_royaltyFee != 0) {
                ZbyteVToken(payable(_dsb.zbyteVToken)).transferFrom(_royaltyPayer, _royaltyReceiver, _royaltyFee);
            }
        } else {
            revert GetRoyaltyFeeInZbyteFailed(_result);
        }


        if (_zbyteCharge != 0) {
            if(_payerEnterprise != bytes4(0)) {
                address _enterprisePolicy = LibDPlatRegistration._doesEnterpriseHavePolicy(_payerEnterprise);
                if(_enterprisePolicy != address(0)) {
                    IEnterprisePaymentPolicy(_enterprisePolicy).updateEnterpriseEligibility(user_, dapp_, functionSig_, _zbyteCharge);
                }
                LibDPlatRegistration._setEntepriseLimit(_payerEnterprise, _currentEnterpriseLimit - _zbyteCharge);
            }
            ZbyteVToken(payable(_dsb.zbyteVToken)).transferFrom(_payer, address(this), _zbyteCharge);
        }
        return _payer;
    }


    /// @dev Executes a transaction and handles Zbyte-related operations.
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
        uint256 _infraFee;
        uint256 _dPlatFee = IZbytePriceFeeder(_dsb.zbytePriceFeeder).getDPlatFeeInZbyte();

        // Execute was successfull, also consider eth sent to execute request
        if (executeResult_) {
            gasConsumedEth_ += reqValue_;
        }       
        uint256 _chargeEth = gasConsumedEth_ >= preChargeEth_ ? gasConsumedEth_ - preChargeEth_ : 0;
        uint256 _refundEth = gasConsumedEth_ > preChargeEth_ ? 0 : preChargeEth_ - gasConsumedEth_;

        uint256 _infraFeePreCharge = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(preChargeEth_);

        if(_chargeEth != 0) {
            uint256 _infraFeeCharge = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(_chargeEth);
            ZbyteVToken(payable(_dsb.zbyteVToken)).transfer(msg.sender, _infraFeePreCharge);
            ZbyteVToken(payable(_dsb.zbyteVToken)).transferFrom(payer_, msg.sender, _infraFeeCharge);
            _infraFee = _infraFeePreCharge + _infraFeeCharge;
        }

        if(_refundEth != 0) {
            uint256 _infraFeePreChargeRefund = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(_refundEth);
            ZbyteVToken(payable(_dsb.zbyteVToken)).transfer(payer_, _infraFeePreChargeRefund);
            ZbyteVToken(payable(_dsb.zbyteVToken)).transfer(msg.sender, _infraFeePreCharge - _infraFeePreChargeRefund);
            _infraFee = _infraFeePreCharge - _infraFeePreChargeRefund;
        }

        if(_dPlatFee != 0) {
            ZbyteVToken(payable(_dsb.zbyteVToken)).burn(payer_, _dPlatFee);
        }

        /// currently royaltyFee is not being charged
        emit ExecuteFees(payer_, _dPlatFee, _infraFee, 0);
    }
}
