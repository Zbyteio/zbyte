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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interface/relay/IRelayWrapper.sol";
import "../utils/ZbyteContext.sol";

/// @title The Relay wrapper to facilitate ZBYT deposit/mint
/// @dev The Relay wrapper to facilitate ZBYT deposit/mint
contract RelayWrapper is Ownable, Pausable, ZbyteContext, IRelayWrapper {
    // errors
    /// @notice error (0xeed987a0): The callback contract address is 0 but ack is set
    error InvalidCallBackContract();
    /// @notice error (0x089c2a3e): The relay contract address is not set for the given relay id
    error RelayContractNotSet(uint256,address,address);
    /// @notice error (0x5c87504d): Caller is not the registered escrow
    error CallerNotEscrow(address,address);

    // events
    /// @notice error (0x14229a64): Address of escrow contract is set
    event EscrowAddressSet(address);
    /// @notice error (0xbe32fe92): Address of Relay is set for given chain id and relay id
    event RelayAddressSet(uint256,uint256,address);

    /// @notice mapping of chain id => relay id => relay address
    /// @dev relay id is an identifier for relay (e.g., 0 -> zbyte relay, 1 -> axelar, etc)
    mapping(uint256 => mapping (uint256 => address)) public relayContract;
    /// @notice mapping of chain id => array of valid relay ids
    mapping(uint256 => uint256[]) chainRelays;
    /// @notice Registered escrow contract address
    address public escrow;

    /// @notice Relay Wrapper constructor
    /// @param forwarder_ Forwarder contact address
    constructor(address forwarder_) {
        _setTrustedForwarder(forwarder_);
    }

     /// @notice Modifier to check if the caller is the registered escrow
    modifier onlyEscrow {
        if (_msgSender() != escrow) {
            revert CallerNotEscrow(msg.sender,escrow);
        }
        _;
    }

    /// @notice Set the address of Escrow contract
    /// @param escrow_ Escrow contract address
    function setEscrowAddress(address escrow_) public onlyOwner {
        if(escrow_ == address(0)) {
            revert ZeroAddress();
        }
        escrow = escrow_;

        emit EscrowAddressSet(escrow_);
    }

    /// @notice Set the address of Relay contract
    /// @param chain_ Chain id for which the relay address is set
    /// @param relayid_ Relay id for which relay address is set
    /// @param relay_  Relay contract Address
    /// @dev set the relay address to 0 to disable the relay
    function setRelayAddress(uint256 chain_,
        uint256 relayid_,
        address relay_)
        public onlyOwner {
        if (relayContract[chain_][relayid_] == address(0)) {
            chainRelays[chain_].push(relayid_);
        }
        relayContract[chain_][relayid_] = relay_;

        emit RelayAddressSet(chain_,relayid_,relay_);
    }

    /// @notice Verify if given relay is a valid one for the given chain id
    /// @param chain_ Chain id for which the relay address is set
    /// @param relay_ Relay contract Address
    function isValidRelay(uint256 chain_, address relay_) external view returns(bool) {
        bool found = false;
        for(uint256 i=0; i < chainRelays[chain_].length; i++) {
            uint256 _relay = chainRelays[chain_][i];
            if (relayContract[chain_][_relay] == relay_) {
                return true;
            }
        }
        return found;
    }

    /// @notice Initiate the cross chain call for deposit/mint
    /// @param relayid_ Relay id that should be used for this call
    /// @param srcChain_ Chain id of source chain
    /// @param destChain_ Chain id of destination chain
    /// @param destContract_ Address of contract to be called on destination chain
    /// @param destCallData_ Calldata for the call on destination chain
    /// @param ack_ Unique hash of the cross chain deposit/mint call
    /// @param callbackContract_ Address of contract on source chain to handle callback
    /// @param relayParams_ Additional data that can be sent to the relay
    /// @dev This function can be called only the the registered escrow contract
    function performCrossChainCall(
        uint256 relayid_,
        uint256 srcChain_,
        uint256 destChain_,
        address destContract_,
        bytes calldata destCallData_,
        bytes32 ack_,
        address callbackContract_,
        bytes calldata relayParams_
    ) external payable onlyEscrow returns (bool) {
        if ((uint256(ack_) != 0) && (callbackContract_ == address(0))) {
            revert InvalidCallBackContract();
        }
        (relayParams_);
        address _srcRelay = relayContract[srcChain_][relayid_]; // contract address on this chain
        address _destRelay = relayContract[destChain_][relayid_]; // contract address on remote

        if ((_srcRelay == address(0)) || (_destRelay == address(0))) {
            revert RelayContractNotSet(relayid_,_srcRelay,_destRelay);
        }

        bytes memory _updatedPayLoad = updatePayload(destChain_,
                                                    destContract_,
                                                    ack_,
                                                    callbackContract_,
                                                    destCallData_);

        (bool success, bytes memory data) = _srcRelay.call(
            abi.encodeWithSignature("callRemote(uint256,address,bytes)",
                destChain_,_destRelay,_updatedPayLoad));
        (data);
        return success;
    }

    /// @notice Update the payload to include additional information
    /// @param destChain_ Chain id of destination chain
    /// @param destContract_ Address of contract to be called on destination chain
    /// @param ack_ Unique hash of the cross chain deposit/mint call
    /// @param callbackContract_ Address of contract on source chain to handle callback
    /// @param data_ original payload
    function updatePayload(uint256 destChain_,
                            address destContract_,
                            bytes32 ack_,
                            address callbackContract_,
                            bytes calldata data_)
        public pure
        returns(bytes memory) {
        return abi.encode(destChain_,destContract_,ack_,callbackContract_,data_);
    }

    /// @notice ERC2771 _msgSender override
    function _msgSender() internal view override(ZbyteContext,Context) returns (address sender) {
        return ZbyteContext._msgSender();
    }

    /// @notice ERC2771 _msgData override
    function _msgData() internal view override(ZbyteContext,Context) returns (bytes calldata) {
        return ZbyteContext._msgData();
    }
}