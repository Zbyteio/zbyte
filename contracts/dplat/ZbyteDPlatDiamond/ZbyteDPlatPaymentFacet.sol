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
    /// @notice Event(0x0f1db6a3) Address of the payer, enterprise hash, DPlat, Infra and Royalty Fee
    event PreExecFees(address,bytes4,uint256,uint256,uint256);
    /// @notice Event(0x5ccdbb95) Address of the payer, Pre Exec charge, Post Exec Charge, Refund if neccessary
    event PostExecFees(address,uint256,uint256,uint256);

    /// error
    /// @notice Error(0x91acbad9) Error details for getRoyaltyFee failure.
    error GetRoyaltyFeeInZbyteFailed(bytes);
    /// @notice Error(0x72b10f2e) Error unusal gas usage for enterprise policy updation.
    error UnusualGasUsageForEnterprisePolicy(uint256,uint256);

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
        LibDPlatBase._setPreExecStates(bytes4(0), 0, address(0), address(0), address(0), bytes4(0));
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        uint256 _dPlatFee = IZbytePriceFeeder(_dsb.zbytePriceFeeder).getDPlatFeeInZbyte();
        uint256 _infraFee = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(ethChargeAmount_);
        uint256 _royaltyFee;
        address _royaltyPayer;
        address _royaltyReceiver;

        bytes4  _feePayerEnterprise;
        uint256 _currentEnterprisePayLimit;
        address _feePayer;
        uint256 _enterpriseEligibilityGas;
        (_feePayerEnterprise, _currentEnterprisePayLimit, _feePayer) = getPayer(user_, dapp_, functionSig_, _infraFee + _dPlatFee);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 functionSelector = bytes4(keccak256("getRoyaltyFeeInZbyte(address,address,bytes4,address,uint256)"));
        LibDiamond.FacetAddressAndPosition memory _facetAddressAndPosition = ds.selectorToFacetAndPosition[functionSelector];
        bytes memory getRoyaltyFeeInZbyteCall = abi.encodeWithSelector(functionSelector, dapp_,user_,functionSig_,_feePayer,_infraFee + _dPlatFee);
        (bool _success, bytes memory _result) = address(_facetAddressAndPosition.facetAddress).delegatecall(getRoyaltyFeeInZbyteCall);

        if(_success) {
            (_royaltyFee, _royaltyReceiver, _royaltyPayer) = abi.decode(_result, (uint256,address,address));
        } else {
            revert GetRoyaltyFeeInZbyteFailed(_result);
        }

        uint256 _totalCharge = _infraFee + _dPlatFee;
        address _enterprisePolicy;
        if(_infraFee != 0 || _dPlatFee != 0 || _royaltyFee != 0) {
            if(_feePayerEnterprise != bytes4(0)) {
                if (_royaltyPayer == _feePayer) 
                    _totalCharge += _royaltyFee;

                _enterprisePolicy = LibDPlatRegistration._doesEnterpriseHavePolicy(_feePayerEnterprise);
                uint256 _startGas = gasleft();
                if(_enterprisePolicy != address(0)) {
                    IEnterprisePaymentPolicy(_enterprisePolicy).updateEnterpriseEligibility(user_, dapp_, functionSig_, int256(_totalCharge));
                }
                _enterpriseEligibilityGas = _startGas - gasleft();
                LibDPlatRegistration._setEntepriseLimit(_feePayerEnterprise, _currentEnterprisePayLimit - (_totalCharge));
            }
            if(_infraFee != 0)
                ZbyteVToken(payable(_dsb.zbyteVToken)).transferFrom(_feePayer, address(this), _infraFee);
            if(_dPlatFee != 0)
                ZbyteVToken(payable(_dsb.zbyteVToken)).burn(_feePayer, _dPlatFee);
            if(_royaltyFee != 0) 
                ZbyteVToken(payable(_dsb.zbyteVToken)).transferFrom(_royaltyPayer, _royaltyReceiver, _royaltyFee);
        }

        LibDPlatBase._setPreExecStates(_feePayerEnterprise, _enterpriseEligibilityGas, _enterprisePolicy, user_, dapp_, functionSig_);
        emit PreExecFees(_feePayer, _feePayerEnterprise, _infraFee, _dPlatFee, _royaltyFee);
        return _feePayer;
    }


    /// @dev Executes a transaction and handles Zbyte-related operations.
    /// @param payer_ The address of the payer initiating the execution.
    /// @param executeResult_ A boolean indicating the success of the execution.
    /// @param reqValue_ The amount of Ether sent with the execution request.
    /// @param gasConsumedEth_ The amount of Ether consumed for gas during execution.
    /// @param preChargeEth_ The amount of Ether charged before execution.
    /// This function can only be called by the `onlyForwarder` modifier.
    function postExecute(address payer_,
                         bool executeResult_,
                         uint256 reqValue_,
                         uint256 gasConsumedEth_,
                         uint256 preChargeEth_) public onlyForwarder {
        LibDPlatBase.DiamondStorage storage _dsb = LibDPlatBase.diamondStorage();
        LibDPlatBase.PreExecStates memory _preExecStates = LibDPlatBase._getPreExecStates();
        uint256 _infraFee;

        // Execute was successfull, also consider eth sent to execute request
        if (executeResult_) {
            gasConsumedEth_ += reqValue_;
        }       
        gasConsumedEth_ += _preExecStates.enterpriseEligibilityGas * tx.gasprice;
        
        uint256 _chargeEth = gasConsumedEth_ >= preChargeEth_ ? gasConsumedEth_ - preChargeEth_ : 0;
        uint256 _refundEth = gasConsumedEth_ > preChargeEth_ ? 0 : preChargeEth_ - gasConsumedEth_;

        uint256 _infraFeePreCharge = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(preChargeEth_);
        uint256 _infraFeeCharge;
        uint256 _infraFeePreChargeRefund;

        if(_chargeEth != 0) {
            _infraFeeCharge = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(_chargeEth);
            ZbyteVToken(payable(_dsb.zbyteVToken)).transfer(msg.sender, _infraFeePreCharge);
            ZbyteVToken(payable(_dsb.zbyteVToken)).transferFrom(payer_, msg.sender, _infraFeeCharge);
            _infraFee = _infraFeePreCharge + _infraFeeCharge;
        }

        if(_refundEth != 0) {
            _infraFeePreChargeRefund = IZbytePriceFeeder(_dsb.zbytePriceFeeder).convertEthToEquivalentZbyte(_refundEth);
            ZbyteVToken(payable(_dsb.zbyteVToken)).transfer(payer_, _infraFeePreChargeRefund);
            ZbyteVToken(payable(_dsb.zbyteVToken)).transfer(msg.sender, _infraFeePreCharge - _infraFeePreChargeRefund);
            _infraFee = _infraFeePreCharge - _infraFeePreChargeRefund;
        }

        uint256 _startGas = gasleft();
        if (_preExecStates.enterprise != bytes4(0)) {
                uint256 _currentEnterpriseLimit = LibDPlatRegistration._getEnterpriseLimit(_preExecStates.enterprise);
                if(_chargeEth != 0) {
                    LibDPlatRegistration._setEntepriseLimit(_preExecStates.enterprise, _currentEnterpriseLimit - (_infraFeeCharge));
                    if (_preExecStates.enterprisePolicy != address(0)) {
                        IEnterprisePaymentPolicy(_preExecStates.enterprisePolicy).updateEnterpriseEligibility(_preExecStates.user, _preExecStates.dapp, _preExecStates.functionSig, int256(_infraFeeCharge));
                    }
                }

                if(_refundEth != 0) {
                    LibDPlatRegistration._setEntepriseLimit(_preExecStates.enterprise, _currentEnterpriseLimit + (_infraFeePreChargeRefund));
                    if (_preExecStates.enterprisePolicy != address(0)) {
                        IEnterprisePaymentPolicy(_preExecStates.enterprisePolicy).updateEnterpriseEligibility(_preExecStates.user, _preExecStates.dapp, _preExecStates.functionSig, -int256(_infraFeePreChargeRefund));
                    }
                }
        }
        uint256 _gasSpendOnEnterpriseUpdate = _startGas - gasleft();
        if ((_preExecStates.enterpriseEligibilityGas * 11 / 10) < _gasSpendOnEnterpriseUpdate && _preExecStates.enterprise != bytes4(0) && _preExecStates.enterprisePolicy != address(0))
            revert UnusualGasUsageForEnterprisePolicy(_preExecStates.enterpriseEligibilityGas, _gasSpendOnEnterpriseUpdate);
        emit PostExecFees(payer_, _infraFee, _infraFeeCharge, _refundEth);
    }
}
