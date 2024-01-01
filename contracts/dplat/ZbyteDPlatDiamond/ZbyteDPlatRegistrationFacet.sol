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
import "../../utils/LibCommonErrors.sol";
import "../../utils/ZbyteContextDiamond.sol";

/// @notice Zbyte DPlat Registration Facet
/// @dev Zbyte DPlat Registration Facet
contract ZbyteDPlatRegistrationFacet is ZbyteContextDiamond {

    /// events
    /// @notice event (0x2a3043c9): Zbyte DPlat provider is registered.
    event ZbyteDPlatProviderRegistred(address,bool);
    /// @notice event (0xb0c62993): Zbyte DPlat provider agent is registered.
    event ZbyteDPlatProviderAgentRegistered(address,address);
    /// @notice event (0xa98ff618): Zbyte DPlat enterprise is registered.
    event ZbyteDPlatEnterpriseRegistered(bytes4,address);
    /// @notice event (0x83439d26): Zbyte DPlat enterprise user is registered.
    event ZbyteDPlatEnterpriseUserRegistered(address,bytes4);
    /// @notice event (0x822d049d): Zbyte DPlat dapp is registered.
    event ZbyteDPlatDappRegistered(address,bytes4);
    /// @notice event (0x75ee1f8e): Zbyte DPlat enterprise limit is set.
    event ZbyteDPlatEnterpriseLimitSet(bytes4,uint256,uint256);

    ///errors
    /// @notice error (0x74f7822a): Provider already registered.
    error ProviderAlreadyRegistered(address);
    /// @notice error (0x232cb27a): Provider not registered.
    error ProviderNotRegistered(address);
    /// @notice error (0x128c088b): Invalid enterprise hash.
    error InvalidEnterprise(bytes4);
    /// @notice error (0xe751ad65): Provider Agent is already registered.
    error ProviderAgentAlreadyRegistered(address);
    /// @notice error (0xd0141a6a): Not a registered provider agent.
    error ProviderAgentNotRegistered(address);
    /// @notice error (0x96271599): Invalid provider.
    error InvalidProvider(address);
    /// @notice error (0x6d998cea): Enterprise is already registered.
    error EnterpriseAlreadyRegistered(bytes4);
    /// @notice error (0xbd825961): Enterprise is not registered.
    error EnterpriseNotRegistered(bytes4);
    /// @notice error (0xca61871b): Not a registered provider.
    error NotARegisteredProvider(address);
    /// @notice error (0x43469070): Enterprise user is already registered.
    error EnterpriseUserAlreadyRegistered(address);
    /// @notice error (0x1b7bfcf8): Enterprise user is not registered.
    error EnterpriseUserNotRegistered(address);
    /// @notice error (0xbcb8afa4): Enterprise dapp is already registered.
    error EnterpriseDappAlreadyRegistered(address);
    /// @notice error (0x31b254a2): Enterprise dapp is not registered.
    error EnterpriseDappNotRegistered(address);

    /// @notice Internal function to set the registration status of a provider.
    /// @param provider_ The address of the provider whose registration status will be set.
    /// @param set_ A boolean indicating whether to set the provider as registered or not.
    /// @dev This function is used internally to manage the registration status of providers.
    function _setRegisteredProvider(address provider_, bool set_) internal {
        if (provider_ == address(0)) {
            revert LibCommonErrors.ZeroAddress();
        }
        LibDPlatProvider.DiamondStorage storage _dsp = LibDPlatProvider.diamondStorage();
        _dsp.registeredProviders[provider_] = set_;
        emit ZbyteDPlatProviderRegistred(provider_, set_);
    }

    /// @notice Internal function to set the registration of a provider agent.
    /// @param agent_ The address of the agent whose provider registration will be set.
    /// @param provider_ The address of the provider associated with the agent.
    /// @dev This function is used internally to manage the registration of provider agents.
    function _setRegisteredProviderAgent(address agent_, address provider_) internal {
        if (agent_ == address(0)) {
            revert LibCommonErrors.ZeroAddress();
        }
        LibDPlatProvider.DiamondStorage storage _dsp = LibDPlatProvider.diamondStorage();
        _dsp.registeredProviderAgent[agent_] = provider_;
        emit ZbyteDPlatProviderAgentRegistered(agent_, provider_);
    }

    /// @notice Internal function to set the registration status of an enterprise.
    /// @param enterprise_ The identifier of the enterprise whose registration status will be set.
    /// @param provider_ The address of the provider associated with the enterprise.
    /// @dev This function is used internally to manage the registration status of enterprises.
    function _setRegisteredEnterprise(bytes4 enterprise_, address provider_) internal {
        if (enterprise_ == bytes4(0)) {
            revert InvalidEnterprise(enterprise_);
        }
        LibDPlatRegistration.DiamondStorage storage _dsr = LibDPlatRegistration.diamondStorage();
        _dsr.registeredEnterprises[enterprise_] = provider_;
        emit ZbyteDPlatEnterpriseRegistered(enterprise_, provider_);
    }

    /// @notice Internal function to set the registration status of an enterprise user.
    /// @param user_ The address of the user whose enterprise registration will be set.
    /// @param enterprise_ The identifier of the enterprise associated with the user.
    /// @dev This function is used internally to manage the registration status of enterprise users.
    function _setRegisteredEnterpriseUser(address user_, bytes4 enterprise_) internal {
        if (user_ == address(0)) {
            revert LibCommonErrors.ZeroAddress();
        }
        LibDPlatRegistration.DiamondStorage storage _dsr = LibDPlatRegistration.diamondStorage();
        _dsr.registeredEnterpriseUsers[user_] = enterprise_;
        emit ZbyteDPlatEnterpriseUserRegistered(user_,enterprise_);
    }

    /// @notice Internal function to set the registration status of an enterprise Dapp.
    /// @param dapp_ The address of the Dapp whose enterprise registration will be set.
    /// @param enterprise_ The identifier of the enterprise associated with the Dapp.
    /// @dev This function is used internally to manage the registration status of enterprise Dapps.
    function _setRegisteredEnterpriseDapp(address dapp_, bytes4 enterprise_) internal {
        if (dapp_ == address(0)) {
            revert LibCommonErrors.ZeroAddress();
        }
        LibDPlatRegistration.DiamondStorage storage _dsr = LibDPlatRegistration.diamondStorage();
        _dsr.registeredDapps[dapp_] = enterprise_;
        emit ZbyteDPlatDappRegistered(dapp_, enterprise_);
    }

    /// @notice Checks if a provider is registered.
    /// @param provider_ The address of the provider to check.
    /// @return A boolean indicating whether the provider is registered.
    function isProviderRegistered(address provider_) public view returns (bool) {
        return LibDPlatRegistration.isProviderRegistered(provider_);
    }

    /// @notice Checks if a provider agent is registered and returns the associated provider's address.
    /// @param agent_ The address of the provider agent to check.
    /// @return The address of the associated registered provider.
    function isProviderAgentRegistered(address agent_) public view returns (address) {
        return LibDPlatRegistration.isProviderAgentRegistered(agent_);
    }

    /// @notice Checks if an enterprise is registered and returns the associated provider's address.
    /// @param enterprise_ The identifier of the enterprise to check.
    /// @return The address of the associated registered provider.
    function isEnterpriseRegistered(bytes4 enterprise_) public view returns (address) {
        return LibDPlatRegistration.isEnterpriseRegistered(enterprise_);
    }

    /// @notice Checks if an enterprise user is registered and returns the associated enterprise identifier.
    /// @param user_ The address of the user to check.
    /// @return The identifier of the associated registered enterprise.
    function isEnterpriseUserRegistered(address user_) public view returns (bytes4) {
        return LibDPlatRegistration.isEnterpriseUserRegistered(user_);
    }

    /// @notice Checks if an enterprise Dapp is registered and returns the associated enterprise identifier.
    /// @param dapp_ The address of the Dapp to check.
    /// @return The identifier of the associated registered enterprise.
    function isEnterpriseDappRegistered(address dapp_) public view returns (bytes4) {
        return LibDPlatRegistration.isEnterpriseDappRegistered(dapp_);
    }

    /// @notice Registers a provider.
    /// @dev Relation between provider, agent, enterprise, users and dapps is as follows:
    ///
    /// zbyte\
    ///____(1) <--------> (n) provider\
    ///____________________________(1) <--------> (n) agent\
    ///____________________________(1) <--------> (n) enterprise\
    ///________________________________________________________(1) <--------> (n) user\
    ///________________________________________________________(1) <--------> (n) dapp
    ///
    ///   For an enterprise usecase, an enterprise can allow users to invoke registered dapps.\
    ///   Users can invoke the contract functions without any need to hold crypto assets.\
    ///   L1 needed for the call is given by the authorized workers and providers compensate them in vERC20.\
    ///\
    ///   For opensource usecase,\
    ///   Users can invoke the contract functions without any need to hold L1 assets.\
    ///   L1 needed for the call is given by the authorized workers and the users compensate them in vERC20\
    ///\
    ///   NOTE: When one of the components (provider, enterprise, agent, user or dapp) is deregistered,\
    ///    all the other components registered under it remain registered.\
    ///    So, if the component is registered again, the entire subtree becomes active again
    function registerProvider() public {
        if (isProviderRegistered(_msgSender())) revert ProviderAlreadyRegistered(_msgSender());
        _setRegisteredProvider(_msgSender(), true);
        _setRegisteredProviderAgent(_msgSender(), _msgSender());
    }

    /// @notice Deregisters a provider.
    function deregisterProvider() public {
        if (!isProviderRegistered(_msgSender())) revert ProviderNotRegistered(_msgSender());
        _setRegisteredProvider(_msgSender(), false);
        _setRegisteredProviderAgent(_msgSender(), address(0));
    }

    /// @notice Registers a provider agent.
    /// @param agent_ The address of the provider agent to register.
    function registerProviderAgent(address agent_) public {
        if (!isProviderRegistered(_msgSender())) revert ProviderNotRegistered(_msgSender());
        if (isProviderAgentRegistered(agent_) != address(0)) revert ProviderAgentAlreadyRegistered(agent_);
        _setRegisteredProviderAgent(agent_, _msgSender());
    }

    /// @notice Deregisters a provider agent.
    /// @param agent_ The address of the provider agent to deregister.
    function deRegisterProviderAgent(address agent_) public {
        address _provider = isProviderAgentRegistered(agent_);
        if (_provider == address(0))  revert ProviderAgentNotRegistered(agent_);
        if (_provider != _msgSender())  revert InvalidProvider(_msgSender());
        if (!isProviderRegistered(_msgSender())) revert ProviderNotRegistered(_msgSender());

        _setRegisteredProviderAgent(agent_, address(0));
    }

    /// @notice Registers an enterprise.
    /// @param enterprise_ The bytes4 identifier of the enterprise to register.
    function registerEnterprise(bytes4 enterprise_) public {
        address _agentProvider = isProviderAgentRegistered(_msgSender());
        address _enterpriseProvider = isEnterpriseRegistered(enterprise_);
        if (_agentProvider == address(0)) revert ProviderAgentNotRegistered(_msgSender());
        if (!isProviderRegistered(_agentProvider)) revert NotARegisteredProvider(_agentProvider);
        if (_enterpriseProvider != address(0)) revert EnterpriseAlreadyRegistered(enterprise_);

        _setRegisteredEnterprise(enterprise_, _agentProvider);
    }

    /// @notice Deregisters an enterprise.
    /// @param enterprise_ The bytes4 identifier of the enterprise to deregister.
    function deregisterEnterprise(bytes4 enterprise_) public {
        address _agentProvider = isProviderAgentRegistered(_msgSender());
        address _enterpriseProvider = isEnterpriseRegistered(enterprise_);
        if (_agentProvider == address(0)) revert ProviderAgentNotRegistered(_msgSender());
        if (!isProviderRegistered(_agentProvider)) revert NotARegisteredProvider(_agentProvider);
        if (_enterpriseProvider != _agentProvider) revert InvalidProvider(_agentProvider);
        if (_enterpriseProvider == address(0)) revert EnterpriseNotRegistered(enterprise_);

        _setRegisteredEnterprise(enterprise_, address(0));
    }

    /// @notice Registers an enterprise user.
    /// @param user_ The address of the user to register.
    /// @param enterprise_ The bytes4 identifier of the enterprise.
    function registerEnterpriseUser(address user_, bytes4 enterprise_) public {
        if (enterprise_ == bytes4(0)) revert InvalidEnterprise(enterprise_);
        address _agentProvider = isProviderAgentRegistered(_msgSender());
        if (_agentProvider == address(0)) revert ProviderAgentNotRegistered(_msgSender());
        if (!isProviderRegistered(_agentProvider)) revert NotARegisteredProvider(_agentProvider);
        if (isEnterpriseRegistered(enterprise_) == address(0)) revert EnterpriseNotRegistered(enterprise_);
        if (isEnterpriseRegistered(enterprise_) != _agentProvider) revert InvalidProvider(_agentProvider);
        if (isEnterpriseUserRegistered(user_) != bytes4(0)) revert EnterpriseUserAlreadyRegistered(user_);

        _setRegisteredEnterpriseUser(user_, enterprise_);
    }

    /// @notice Deregisters an enterprise user.
    /// @param user_ The address of the user to deregister.
    function deregisterEnterpriseUser(address user_) public {
        bytes4  _userEnterprise = isEnterpriseUserRegistered(user_);
        address _agentProvider = isProviderAgentRegistered(_msgSender());
        if (_userEnterprise == bytes4(0)) revert EnterpriseUserNotRegistered(user_);
        if (isEnterpriseRegistered(_userEnterprise) == address(0)) revert EnterpriseNotRegistered(_userEnterprise);
        if (_agentProvider == address(0)) revert ProviderAgentNotRegistered(_msgSender());
        if (!isProviderRegistered(_agentProvider)) revert NotARegisteredProvider(_agentProvider);
        if (isEnterpriseRegistered(_userEnterprise) != _agentProvider) revert InvalidProvider(_agentProvider);

        _setRegisteredEnterpriseUser(user_, bytes4(0));
    }

    /// @notice Registers a Dapp for an enterprise.
    /// @param dapp_ The address of the Dapp to register.
    /// @param enterprise_ The bytes4 identifier of the enterprise.
    function registerDapp(address dapp_, bytes4 enterprise_) public {
        if (enterprise_ == bytes4(0)) revert InvalidEnterprise(enterprise_);
        address _agentProvider = isProviderAgentRegistered(_msgSender());
        if (_agentProvider == address(0)) revert ProviderAgentNotRegistered(_msgSender());
        if (!isProviderRegistered(_agentProvider)) revert NotARegisteredProvider(_agentProvider);
        if (isEnterpriseRegistered(enterprise_) == address(0)) revert EnterpriseNotRegistered(enterprise_);
        if (isEnterpriseRegistered(enterprise_) != _agentProvider) revert InvalidProvider(_agentProvider);
        if (isEnterpriseDappRegistered(dapp_) != bytes4(0)) revert EnterpriseDappAlreadyRegistered(dapp_);

        _setRegisteredEnterpriseDapp(dapp_, enterprise_);
    }

    /// @notice Deregisters a Dapp for an enterprise.
    /// @param dapp_ The address of the Dapp to deregister.
    function deregisterDapp(address dapp_) public {
        bytes4  _dappEnterprise = isEnterpriseDappRegistered(dapp_);
        address _agentProvider = isProviderAgentRegistered(_msgSender());
        if (_dappEnterprise == bytes4(0)) revert EnterpriseDappNotRegistered(dapp_);
        if (isEnterpriseRegistered(_dappEnterprise) == address(0)) revert EnterpriseNotRegistered(_dappEnterprise);
        if (_agentProvider == address(0)) revert ProviderAgentNotRegistered(_msgSender());
        if (!isProviderRegistered(_agentProvider)) revert NotARegisteredProvider(_agentProvider);
        if (isEnterpriseRegistered(_dappEnterprise) != _agentProvider) revert InvalidProvider(_agentProvider);

        _setRegisteredEnterpriseDapp(dapp_, bytes4(0));
    }

    /// @notice Sets the enterprise limit for a specific enterprise.
    /// @param enterprise_ The bytes4 identifier of the enterprise.
    /// @param amount_ The new limit amount.
    function setEnterpriseLimit(bytes4 enterprise_, uint256 amount_) public {
        address _agentProvider = isProviderAgentRegistered(_msgSender());
        address _enterpriseProvider = isEnterpriseRegistered(enterprise_);
        if (_agentProvider == address(0)) revert ProviderAgentNotRegistered(_msgSender());
        if (!isProviderRegistered(_agentProvider)) revert NotARegisteredProvider(_agentProvider);
        if (_enterpriseProvider != _agentProvider) revert InvalidProvider(_agentProvider);
        if (_enterpriseProvider == address(0)) revert EnterpriseNotRegistered(enterprise_);

        LibDPlatRegistration._setEntepriseLimit(enterprise_, amount_);
    }

    function getEnterpriseLimit(bytes4 enterprise_) public view returns(uint256) {
        return LibDPlatRegistration._getEnterpriseLimit(enterprise_);
    }
}
