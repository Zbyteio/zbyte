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

/// @title The Zbyte Relay contract
/// @dev The Zbyte Relay contract
contract ZbyteRelay is Ownable, ZbyteContext {
    // errors
    /// @notice error (0x0ca968d8): Caller is not an approved caller
    error NotApproved(address);
    /// @notice error (0x26fb3778): Caller is not the RelayWrapper or this contract
    error NotRelayWrapperOrSelf(address,address);
    /// @notice error (0xc16b00ce): Current chain id does not match with the one sent in payload
    error InvalidChain(uint256,uint256);

    // events
    /// @notice event (0x9a3d7ba1): Received the request to perform a remote call
    event RelayCallRemoteReceived(uint256,address,uint256,address,bytes);
    /// @notice event (0xceeaa702): Executed the call request from a source chain
    event RelayReceiveCallExecuted(bytes,bool,uint256);
    /// @notice event (0x2658b600): Relay Wrapper address is set
    event RelayWrapperSet(address);
    /// @notice event (0xe89d9bcd): Approvee address is set
    event RelayApproveeAdded(address);

    /// @notice mapping of approved addresses.  Only these addresses can invoke the 'receiveCall'
    mapping(address => bool) approved;
    /// @notice Address of the RelayWrapper (on core)
    IRelayWrapper public relayWrapper;

    /// @notice Zbyte Relay constructor
    /// @param forwarder_ Forwarder contact address
    constructor(address forwarder_) {
        _setTrustedForwarder(forwarder_);
    }

    /// @notice Modifier to check if the caller is approved or this contract
    modifier onlyApprovedOrSelf {
        if((approved[_msgSender()] != true) && (_msgSender() != address(this))) {
             revert NotApproved(_msgSender());
        }
        _;
    }

    /// @notice Modifier to check if the caller is RelayWrapper or this contract
    modifier onlyRelayWrapperOrSelf {
        if ((_msgSender() != address(relayWrapper)) && (_msgSender() != address(this))) {
            revert NotRelayWrapperOrSelf(_msgSender(),address(relayWrapper));
        }
        _;
    }

    /// @notice Set the RelayWrapper contract address
    /// @param wrapper_ RelayWrapper contact address
    function setRelayWrapper(address wrapper_) external onlyOwner {
        if(wrapper_ == address(0)) {
            revert ZeroAddress();
        }

        relayWrapper = IRelayWrapper(wrapper_);

        emit RelayWrapperSet(wrapper_);
    }

    /// @notice Set the approvee address
    /// @param approvee_ Address of the approvee
    function addRelayApprovee(address approvee_) external onlyOwner {
        if(approvee_ == address(0)) {
            revert ZeroAddress();
        }
        approved[approvee_] = true;

        emit RelayApproveeAdded(approvee_);
    }

    /// @notice Initiate the remote chain call
    /// @param destChain_ Chain id of destination chain
    /// @param destRelay_ Address of the trusted relay on destination chain
    /// @param payload_ Payload to be used for the destination call
    function callRemote(uint256 destChain_,
                        address destRelay_,
                        bytes memory payload_) // (destChain,destContract,ack,callbackContract,destCallData_)
                        public
                        payable
                        onlyRelayWrapperOrSelf
                        returns (bool) {
        // initiate the remote call on source
        (uint256 _destChain,,,,) =
                abi.decode(payload_,(uint256,address,bytes32,address,bytes));
        require(_destChain == destChain_, "Invalid destination chain");

        // loop if dest == src
        if (destChain_ == block.chainid) {
            this.receiveCall(block.chainid,address(this),payload_);
        }

        emit RelayCallRemoteReceived(block.chainid,address(this),destChain_,destRelay_,payload_);
        return true;
    }

    /// @notice Handle the call received from source chain
    /// @param srcChain_ Chain id of source chain
    /// @param srcRelay_ Address of the trusted relay on source chain
    /// @param payload_ Payload to be used for the call on this chain
    /// @dev Call can be made only by approved accounts or self
    function receiveCall(uint256 srcChain_,
                         address srcRelay_,
                         bytes memory payload_) // (destRelay_,(destChain,destContract,ack,callbackContract,destCallData_))
        onlyApprovedOrSelf
        external
        returns(bool) {
        // receive the call on dest
        (uint256 _destChain, address _destContract,
         bytes32 _ack, address _callbackContract, bytes memory _data) = 
                abi.decode(payload_,(uint256,address,bytes32,address,bytes));
        if(_destChain != block.chainid) {
            revert InvalidChain(_destChain, block.chainid);
        }
        // TODO add this line back
        //require(_destRelay == address(this), "Invalid destination contract");

        (bool success, bytes memory returnData) = _destContract.call(_data);
        uint256 retval = abi.decode(returnData,(uint256));
        
        emit RelayReceiveCallExecuted(payload_,success,retval);


        if ((_ack != bytes32(0)) && (_callbackContract != address(0))) {
            bytes memory _updatedPayload = updatePayload(srcChain_,_callbackContract,
                                bytes32(0),address(0),
                               abi.encodeWithSignature("callbackHandler(uint256,bytes32,bool,uint256)",
                                _destChain,_ack,success,retval));
            this.callRemote(srcChain_,srcRelay_,_updatedPayload);
        }
        return true;
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
                            bytes memory data_)
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