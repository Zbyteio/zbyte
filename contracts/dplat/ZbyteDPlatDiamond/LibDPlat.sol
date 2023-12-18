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

/// @notice Library for DPlat base storage and functions
/// @dev Library for DPlat base storage and functions
library LibDPlatBase {

    /// @notice Diamond storage for DPlat Base struct
    struct DiamondStorage {
        address zbyteVToken; 
        address zbytePriceFeeder;
        mapping (address => uint256) royaltyZbyte;
    }

    /// @notice Retrieves the DiamondStorage struct for the library.
    /// @dev zbyteVToken: The address of the ZbyteVToken\
    ///  zbyteValueInNativeEthGwei: The value of Zbyte in native Ether (in Gwei)\
    ///  zbyteBurnFactor: Burn factor, represents the percent of gas used that will be 'burnt'
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.LibDPlatBase.v1");
        assembly {
            ds.slot := storagePosition
        }
    }

    /// @notice Gets the ZbyteVToken address.
    /// @return The address of the ZbyteVToken.
    function _getZbyteVToken() internal view returns (address) {
        DiamondStorage storage _dsb = diamondStorage();
        return _dsb.zbyteVToken;
    }

    function _getZbytePriceFeeder() internal view returns (address) {
        DiamondStorage storage _dsb = diamondStorage();
        return _dsb.zbytePriceFeeder;
    }

    function _setRoyaltyInZbyte(address dapp_, uint256 amount_) internal {
        DiamondStorage storage _dsb = diamondStorage();
        _dsb.royaltyZbyte[dapp_] = amount_;
    }

    function _getRoyaltyInZbyte(address dapp_) internal view returns(uint256) {
        DiamondStorage storage _dsb = diamondStorage();
        return _dsb.royaltyZbyte[dapp_];
    }
}

/// @notice Library for DPlat registration storage and functions
/// @dev Library for DPlat registration storage and functions
library LibDPlatRegistration {

    /// @notice Diamond storage for DPlat registration struct
    struct DiamondStorage {
        mapping(bytes4 => address) registeredEnterprises;
        mapping(bytes4 => address) registeredEnterprisePolicy;
        mapping(address => bytes4) registeredDapps;
        mapping(address => bytes4) registeredEnterpriseUsers;
        mapping(bytes4 => uint256) enterpriseLimit;
    }

    /// @notice Retrieves the DiamondStorage struct for the library.
    /// @dev registeredEnterprises: Mapping of registered enterprises by bytes4 ID\
    ///  registeredEnterprisePolicy: Mapping of enterprise policies by bytes4 ID\
    ///  registeredDapps: Mapping of registered Dapps by address\
    ///  registeredEnterpriseUsers: Mapping of registered enterprise users by address\
    ///  enterpriseLimit: Mapping of enterprise limits by bytes4 ID
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.LibDPlatRegistration.v1");
        assembly {
            ds.slot := storagePosition
        }
    }

    /// @notice Gets the enterprise limit for a given enterprise ID.
    /// @param enterprise_ The enterprise ID.
    /// @return The enterprise limit.
    function _getEnterpriseLimit(bytes4 enterprise_) internal view returns (uint256) {
        DiamondStorage storage _dsp = diamondStorage();
        return _dsp.enterpriseLimit[enterprise_];
    }

    /// @notice Sets the enterprise limit for a given enterprise ID.
    /// @param enterprise_ The enterprise ID.
    /// @param amount_ The limit amount to set.
    function _setEntepriseLimit(bytes4 enterprise_, uint256 amount_) internal {
        DiamondStorage storage _dsp = diamondStorage();
        _dsp.enterpriseLimit[enterprise_] = amount_;
    }

    /// @notice Checks if an enterprise has a registered policy and retrieves the policy address.
    /// @param enterprise_ The enterprise ID.
    /// @return Enterprise payment policy address.
    function _doesEnterpriseHavePolicy(bytes4 enterprise_) internal view returns (address) {
        DiamondStorage storage _dsp = diamondStorage();
        return _dsp.registeredEnterprisePolicy[enterprise_];
    }

    /// @notice Checks if the given provider is registered
    /// @param provider_ The provider address
    /// @return bool indicating if the provider is registered
    function isProviderRegistered(address provider_) internal view returns(bool) {
        LibDPlatProvider.DiamondStorage storage _dsp = LibDPlatProvider.diamondStorage();
        return _dsp.registeredProviders[provider_];
    }

    /// @notice Checks if the given agent is registered
    /// @param agent_ The agent address
    /// @return returns the address of provider if registered, or address(0)
    function isProviderAgentRegistered(address agent_) internal view returns(address) {
        LibDPlatProvider.DiamondStorage storage _dsp = LibDPlatProvider.diamondStorage();
        return _dsp.registeredProviderAgent[agent_];
    }

    /// @notice Checks if the given enterprise is registered
    /// @param enterprise_ The enterprise bytes4 ID
    /// @return returns the address of provider if registered, or address(0)
    function isEnterpriseRegistered(bytes4 enterprise_) internal view returns(address) {
        LibDPlatRegistration.DiamondStorage storage _dsr = LibDPlatRegistration.diamondStorage();
        return _dsr.registeredEnterprises[enterprise_];
    }

    /// @notice Checks if the given user is registered with an enterprise
    /// @param user_ The user address
    /// @return returns the address of provider if registered, or address(0)
    function isEnterpriseUserRegistered(address user_) internal view returns(bytes4) {
        LibDPlatRegistration.DiamondStorage storage _dsr = LibDPlatRegistration.diamondStorage();
        return _dsr.registeredEnterpriseUsers[user_];
    }

    /// @notice Checks if the given dapp (contract) is registered with an enterprise
    /// @param dapp_ The contract address
    /// @return returns the address of provider if registered, or address(0)
    function isEnterpriseDappRegistered(address dapp_) internal view returns(bytes4) {
        LibDPlatRegistration.DiamondStorage storage _dsr = LibDPlatRegistration.diamondStorage();
        return _dsr.registeredDapps[dapp_];
    }
}

/// @notice Library for DPlat provider storage and functions
/// @dev Library for DPlat provider storage and functions
library LibDPlatProvider {

    /// @notice Diamond storage for DPlat provider struct
    struct DiamondStorage {
        mapping(address => bool) registeredProviders;
        mapping(address => address) registeredProviderAgent;
    }

    /// @notice Retrieves the DiamondStorage struct for the library.
    /// @dev registeredProviders: Mapping of registered providers by address\
    ///  registeredProviderAgent: Mapping of registered provider agents by address
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.LibDPlatProvider.v1");
        assembly {
            ds.slot := storagePosition
        }
    }
}
