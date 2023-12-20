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

import "../../utils/ZbyteContextDiamond.sol";

library LibDPlatRoyalty {
    /// @notice Diamond storage for DPlat Base struct
    struct DiamondStorage {
        mapping (address => uint256) royaltyDapp;
    }

    /// @notice Retrieves the DiamondStorage struct for the library.
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.LibDPlatRoyalty.v1");
        assembly {
            ds.slot := storagePosition
        }
    }
}

/**
 * @title ZbyteDPlatRoyaltyFacet
 * @dev This contract extends ZbyteContextDiamond and provides functionality related to royalty fees in Zbyte.
 */
contract ZbyteDPlatRoyaltyFacet is ZbyteContextDiamond {

    /**
     * @dev Retrieves the royalty fee in Zbyte for a specific DApp function.
     * @param dapp_ The address of the DApp.
     * @param user_ The address of the user involved in the DApp function.
     * @param functionSig_ The function signature of the DApp function.
     * @param payer_ The address of the entity paying the royalty fee.
     * @param zbyteCharge_ The Zbyte charge associated with the DApp function.
     * @return uint256 The royalty fee in Zbyte.
     * @return address The address of the payer.
     */
    function getRoyaltFeeInZbyte(
        address dapp_,
        address user_,
        bytes4 functionSig_,
        address payer_,
        uint256 zbyteCharge_
    ) external view returns(uint256, address, address) {
        (user_, functionSig_, zbyteCharge_);

        LibDPlatRoyalty.DiamondStorage storage _dsr = LibDPlatRoyalty.diamondStorage();
        /// royalty amount, receiver address, payer address 
        return (_dsr.royaltyDapp[dapp_], dapp_,payer_);
    }
}
